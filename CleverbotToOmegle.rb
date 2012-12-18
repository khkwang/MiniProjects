require 'rubygems'
require 'watir-webdriver'

class Omegle
  
  def start
    @count = 0
    @browser = Watir::Browser.new :chrome
    @browser.goto("http://omegle.com/")
    @browser.image(:id, 'textbtn').click
  end
  
  def done?
    new_button = @browser.button(:value, 'Start a new conversation')
    if new_button.exists?
      next_chat
      return true
    end
    return false
  end
  
  def disconnect
    @browser.button(:class, 'disconnectbtn').click
    @browser.button(:class, 'disconnectbtn').click
  end
  
  def next_chat
    #@browser.link(:text, 'Get a link').click
    if @count > 10
      gets
    end
    @count = 0
    @browser.button(:value, 'Start a new conversation').click
  end
  
  def say(input)
    @browser.text_field(:class, 'chatmsg').set(input)
    if !done?
      @browser.button(:class, 'sendbtn').click
    end
  end
  
  def ready?
    begin
      logs = @browser.div(:class, 'logbox').ps
      return (logs.last.class_name == 'strangermsg' or done?)
    rescue Selenium::WebDriver::Error::StaleElementReferenceError
      return false
    end
  end
  
  def listen
    until ready?
      sleep 0.1
    end
    begin
      logs = @browser.div(:class, 'logbox').ps
      if logs.last.class_name == 'strangermsg'
        @count = @count + 1
        return logs.last.text.split("Stranger: ")[1]
      else
        return 'FINISH'
      end
    rescue Selenium::WebDriver::Error::StaleElementReferenceError
      return listen
    end
  end
  
end

class CleverBot
  
  def start
    @browser = Watir::Browser.new :chrome
    @browser.goto("http://cleverbot.com/")
  end
  
  def ready?
    begin
      return @browser.button(:id, 'sayit').enabled?
    rescue Selenium::WebDriver::Error::StaleElementReferenceError
      return false
    end
  end
  
  def say(input)
    until ready?
      sleep 0.1
    end
    @browser.text_field(:id, 'stimulus').set(input)
    @browser.button(:id, 'sayit').click
  end
  
  def listen
    begin
      response = @browser.span(:id, 'typArea')
      until response.exists?
        sleep 0.1
      end
      prev = response.text
      sleep 0.5
      while prev != response.text
        prev = response.text
        sleep 0.5
      end
      response = response.text
      if ((response.strip == '|') or (response.strip == ''))
        return listen
      end
      return response.downcase.chomp('.')
    rescue Selenium::WebDriver::Error::StaleElementReferenceError
      return listen
    end
  end
  
  def next
    @browser.close
    start
  end
  
end

cleverbot = CleverBot.new
cleverbot.start
omegle = Omegle.new
omegle.start

input = omegle.listen

while true
  cleverbot.say(input)
  input = cleverbot.listen
  omegle.say(input)
  input = omegle.listen
  if input == 'FINISHED'
    cleverbot.next
    input = 'hi'
  end
end