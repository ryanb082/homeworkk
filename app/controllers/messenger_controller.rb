class MessengerController < ApplicationController
	require 'json'
	require 'httparty'
	include MessengerHelper

	def receive_message
		checkFacebookToken()
 		$webhook = JSON.parse(request.raw_post)
 		page_access_token = 'EAAZAjj9YZAiZC0BAMAQ5ZCebCvomc1uET1dns9KbhNleTZChhsKyo5WAD0fXvdZAj5RbZBEUbADcTactqxkleZB3XmmeEH348xdk4dibeQzMhaDxNQtF51ZA0Vf8ZAqnlCSgzhpl286TwFoPK3gFGpPK4Rdk0rvmp0hh5gmpfPWbOJCwZDZD'

	  body = {
	   recipient: {
	     id: '134381003642835'
	   },
	   message: {
	     text: 'hi alec'
	   }
	  }.to_json
	  
	  response = HTTParty.post(
	   "https://graph.facebook.com/v2.6/me/messages?access_token=#{page_access_token}",
	   body: body,
	   headers: { 'Content-Type' => 'application/json' }
	  )
	  render nothing => true, status: 200
 	end

 	def webhook_inspect
 		
 	end
 
end