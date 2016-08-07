class HooksController < ApplicationController
  skip_before_filter :verify_authenticity_token

  require 'uri'
  
  def receive
    # application/x-www-form-urlencoded
    data = request.raw_post
    $webhook_data = URI::decode_www_form(data)
  end
	
  def test
    if !$webhook_data.nil?
      @test = $webhook_data

      @user_exist = User.where("conversation_id = ?", @test[0][1])
    end
  end

end