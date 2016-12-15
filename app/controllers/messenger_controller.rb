class MessengerController < ApplicationController
	require 'json'
	require 'httparty'
	include MessengerHelper

	def receive_message
		#variable with all the webhook data
 		$webhook = JSON.parse(request.raw_post)
 		# person who sent the text; id
 		@recipient = $webhook["entry"][0]["messaging"][0]["sender"]["id"]
 		# what text the user sent
 		@userText = $webhook["entry"][0]["messaging"][0]["message"]["text"].downcase unless $webhook["entry"][0]["messaging"][0]["message"].nil?
 		# a list of positve responses to respond with if user doesn't have homework
 		@positiveResponses = ["that's grrrreat", "that's awesome!", "yay! no homework!", "finally, a break from some homework", "awesome, just what i wanted to hear", "yay, some good news today", "that's almost better than harry potter", "time to celebrate, come on!"]
		# a list of negative responses if user has homework
		@negativeResponses = ["booooo", "what a shame", "ugh, that stinks", "your teacher needs to chill out on the homework", "that's so sad to hear", "that sucks, at least you look good today", "that sucks more than a vacuum", "that's worse than when dumbledore died"]
		# if user sends a text, but has nothing to do with homework and they're signed up
		@defaultResponses = ["hardy har har"]
		# setting variables to false, to know what and if I sent a message
		@sentMessage = false
		@sentKeyWords = false
		@sentConfirmation = false
		$checkKeyWords = nil
		# list of all classes that need to be delt with
 		currentClasses = Grouparray.all
 		# random numbe from 0 to seven, to get a random response from the array
 		randomNum = rand(0..7)
 		
 		# function that checks if the user exists based on their text id
 		@checkUserExists = Messagehuman.checkUserExists(@recipient)
 		# if @checkUserExists return false, then send the sign up button 
	 	if @checkUserExists == false
 			Messagehuman.sendButton(@recipient)
 			# marking that I did send a messsage
 			@sentMessage = true
 		end

 		# checking if the user says cancel
		if @userText == "cancel"
			# if true, then delete classes they might have to deal with
			@grouparrays = Grouparray.all.where(conversation_id: @recipient)
			if !@grouparrays.nil? || !@grouparray.empty?
				# each outstanding group to deal with (should just be one)
 				@grouparrays.each do |group|
 					# find the corresponding group, and reset anything to do with that homework
	 				@group = Group.find_by(conversation_id: group.conversation_id, group_name: group.group_name, group_day: group.group_day)
	 				@group.update(homework_assigned: nil, homework_assigned: nil)
	 				# destroy the group array
	 				group.destroy
	 			end
			end
			# send a message confirming that you have done the previous
			Messagehuman.sendMessage(@recipient, "ok, let me know if you need anything else")
			# market that I did send a message
			@sentMessage = true
		else
			# making sure that groups response is empty/nil
			if !$groupsResponse.nil? && !$groupsResponse.empty?
				# for each group in group response
				$groupsResponse.each do |group|
					# if the group name matches to group the user said in the text
					if group.group_name == @userText
						# we know that the user has homework for that class
						group.update(homework_assigned: true)
						@group = group.as_json # convert the group to json
						@group["id"] = nil # removing the id
						@group.delete("name") # delete name
						# check if there are any outstanding groups, if so, delete them
						checkExistingGroupArray = Grouparray.find_by(conversation_id: group.conversation_id)
						checkExistingGroupArray.destroy if !checkExistingGroupArray.nil?
						# create the new group array and save them
						groupArrayNew = Grouparray.new(@group)
						groupArrayNew.save
						Messagehuman.sendMessageBubbles(@recipient) # send the message bubbles
			 			sleep(2) # let the program sleep for 1 second
			 			Messagehuman.sendMessage(@recipient, @negativeResponses[randomNum]) # sending a negative response
			 			Messagehuman.sendMessageBubbles(@recipient) # send more message bubles
			 			sleep(2) # let the program sleep for one second
			 			Messagehuman.sendMessage(@recipient, 'what homework do you have for ' + @group["group_name"] + '?')
			 			# markers that I have sent messages
			 			@sentMessage = true
			 			@sentKeyWords = true
					end
				end
			end

			# checking for key words (this would only happen if the other stuff above hasn't happend)
			$checkKeyWords = Messagehuman.checkKeyWords(@recipient, @userText)
			if !$checkKeyWords.nil? # if the function doesn't return nil
		 	if $checkKeyWords == true # if true, which means, all keywords were found
		 		Messagehuman.sendMessageBubbles(@recipient) # send message bubbles
					sleep(1) # let the code sleep for 1 second
					Messagehuman.sendMessage(@recipient, @negativeResponses[randomNum]) # send a negative response
					Messagehuman.sendMessageBubbles(@recipient) # send more fricken bubbles
					sleep(1)
					Messagehuman.sendMessage(@recipient, 'what homework do you have for ' + $subject.downcase + '?') # send the question
					# markers that I've sent a message
					@sentKeyWords = true 
					@sentMessage = true
				# on the other hand, if the subject hasn't been found
				elsif $checkKeyWords == false && !$possibleSubjects.empty? && @sentConfirmation == false
					# send the message of what they meant to type
					Messagehuman.sendGroupConfirmMessage(@recipient, $possibleSubjects)
					#setting the gropus response
					$groupsResponse = Array.new
					# setting the markers that I've sent a message
					@sentMessage = true
					@sentKeyWords = true
					@sentConfirmation = true
					# foreach possible subject
					$possibleSubjects.each do |group|
						# find that group
						@group = Group.find_by(group_name: group, conversation_id: @recipient, group_day: 0.hours.ago.strftime("%A").downcase)
						if !@group.nil?
							# push it to the array
							$groupsResponse.push(@group)
						end
					end
				else
				end
			end

			if @sentKeyWords == false
			# for every group in the grouparray (ie, and outstaning group)
			currentClasses.each do |group| 
				randomNum = rand(0..7)
				# if a group matches who just sent a message
				if group.conversation_id == @recipient
					# if the user has said yes
					if @userText == "yes"
						# find the group, the user was talking about
						@group = Group.find_by(conversation_id: group.conversation_id, group_name: group.group_name, group_day: group.group_day)
						# putsing into the logs the class
						puts "group thing: " + @group.group_name.inspect
						# updating that we do have homework, and also updating the grouparray
						@group.update(homework_assigned: true)
						@grouparray = Grouparray.find_by(id: group.id)
						@grouparray.update(homework_assigned: true)
						Messagehuman.sendMessageBubbles(group.conversation_id) # send the message bubbles
						sleep(2) # sleeping in the code
						Messagehuman.sendMessage(group.conversation_id, @negativeResponses[randomNum]) # send a negative response
						Messagehuman.sendMessageBubbles(group.conversation_id) # send the message bubbles
						sleep(2) # sleeping in the code
						Messagehuman.sendMessage(group.conversation_id, 'what homework do you have?') # asking what homework there is
						@sentMessage = true # marker that I sent a message
					# if the user responds no
					elsif @userText == "no"
						# send the messsage bubbles
						Messagehuman.sendMessageBubbles(group.conversation_id)
						sleep(2) # sleep in the code for 2 secs
						Messagehuman.sendMessage(group.conversation_id, @positiveResponses[randomNum]) # send a positive response
						#find the grouparray and destroy that
						@groupArrayGroup = Grouparray.find_by(id: group.id)
						@groupArrayGroup.destroy
						# find the corresponsing gropu and update that
						@group = Group.find_by(conversation_id: group.conversation_id, group_name: group.group_name, group_day: group.group_day)
						@group.update(homework_assigned: false)
						# marker that I did send a message
						@sentMessage = true
					# if there is homework
					elsif group.homework_assigned == true
						# then update that group of the homework I have
						@group = Group.find_by(conversation_id: group.conversation_id, group_name: group.group_name, group_day: group.group_day)
						@group.update(homework_assignment: @userText)
						# find and destroy the group array
						@groupArray = Grouparray.find_by(id: group.id)
						@groupArray.destroy
						Messagehuman.sendMessageBubbles(group.conversation_id) # send more message bubbles
						sleep(1) # sleep for 1 sec
						Messagehuman.sendMessage(group.conversation_id, 'ok, got it!') # send that I have it
						# i sent the message
						@sentMessage = true
					else
					end
					end
				end
			end
			# if there has been no message sent, then send a default response
			if @sentMessage == false
				# sending the default response
				Messagehuman.sendMessage(@recipient, @defaultResponses[0])
				@sentMessage = true # marker that I sent a message
			end
 		end
 	end

 	# method to check if facebook webhook is authentic
 	def check_token
 		# function to check if webhook is real
 		checkFacebookToken()
 	end

 	# just an inspect page for whatever I watn
 	def webhook_inspect
 	end
 
end