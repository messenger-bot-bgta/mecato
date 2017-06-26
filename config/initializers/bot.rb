include Facebook::Messenger

Bot.on :message do |message|
  message.typing_on
  message.reply(text: 'Hello, human!')
end

Bot.on :postback do |postback|

  if postback.payload == 'USER_DEFINED_PAYLOAD'
    postback.reply(text: 'Bienvenido a Mecato!')
    postback.reply(text: 'Cual es tu tienda mas cercana ?')

    elements = Shop.all.map do |shop|
           {
            title: shop.name,
            #image_url: "https://petersfancybrownhats.com/company_image.png",
            subtitle: "We\'ve got the right hat for everyone.",
            buttons: [
              {
                type: "web_url",
                url: "https://petersfancybrownhats.com",
                title: "View Website"
              }
            ]      
          }
    end


    postback.reply({
      attachment: {
      type: "template",
      payload: {
        template_type: "generic",
        elements: elements
      }
    }
    })

  end

end




class ServerNoError < Facebook::Messenger::Server

  def call(env)
    begin
      super
    rescue Exception => e

        send("\xF0\x9F\x98\xB1")
        send(e.inspect)
        send(e.backtrace.join("\n")[0..636] + "...")

        @response.status = 200
        @response.finish

    end
  end

  private

  def send(text)

     sender_id = parsed_body["entry"][0]["messaging"][0]["sender"]["id"]

      Bot.deliver({
        recipient: {
          id: sender_id
        },
        message: {
          text: text
        }
      }, access_token: ENV['ACCESS_TOKEN']) 
  end
  
end

# SEND API

module Facebook
  module Messenger
    module Incoming
      # Common attributes for all incoming data from Facebook.
      module Common

        def show_typing(is_active)
          payload = {
            recipient: sender,
            sender_action: (is_active)?'typing_on':'typing_off'
          }
          Facebook::Messenger::Bot.deliver(payload, access_token: access_token)
        end
        def mark_as_seen
          payload = {
            recipient: sender,
            sender_action: 'mark_seen'
          }
          Facebook::Messenger::Bot.deliver(payload, access_token: access_token)
        end
        def reply_with_text(text)
          reply(text: text)
        end
        def reply_with_image(image_url)
          reply(
                attachment: {
                    type: 'image',
                    payload: {
                      url: image_url
                    }
                  }
          )
        end
        def reply_with_audio(audio_url)
          reply(
                attachment: {
                    type: 'audio',
                    payload: {
                      url: audio_url
                    }
                  }
          )
        end
        def reply_with_video(video_url)
          reply(
                attachment: {
                    type: 'video',
                    payload: {
                      url: viedo_url
                    }
                  }
          )
        end
        def reply_with_file(file_url)
          reply(
                attachment: {
                    type: 'file',
                    payload: {
                      url: file_url
                    }
                  }
          )
        end
        def ask_for_location(text)
          reply({
            text: text,
            quick_replies:[
              {
                content_type:"location",
              }
            ]
          })
        end 
        def has_attachments?
          attachments != nil
        end 
        def is_location_attachment?
          has_attachments? && attachments.first["type"] == "location"
        end
        def is_image_attachment?
          has_attachments? && attachments.first["type"] == "image"
        end
        def is_video_attachment?
          has_attachments? && attachments.first["type"] == "video"
        end
        def is_audio_attachment?
          has_attachments? && attachments.first["type"] == "audio"
        end
        def is_file_attachment?
          has_attachments? && attachments.first["type"] == "file"
        end
        def location
          coordinates = attachments.first['payload']['coordinates']
          [coordinates['lat'], coordinates['long']] 
        end
        def access_token
          Facebook::Messenger.config.provider.access_token_for(recipient)
        end
      end
    end
  end
end
# END
