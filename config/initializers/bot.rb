include Facebook::Messenger

Bot.on :message do |message|
  user = User.find_or_create_by(messenger_id: message.sender['id'])

  if user.step == "phone"
    user.cart["phone"] = message.text

    message.reply(text: "Gracias")
    message.reply(text: "Tu orden llegara en 10 minutos mas o menos")

    products = Product.where(id: user.cart["product"])

    elements = products.map do |product|
          {
            title: product.name,
            subtitle: "100% Soft and Luxurious Cotton",
            quantity: 1,
            price: product.price,
            currency: "COP",
          }
    end

    total = products.map { |x| x.price }.reduce(&:+)

    message.reply({
    attachment: {
      type: "template",
      payload: {
        template_type: "receipt",
        recipient_name: "Stephane Crozatier",
        order_number: Time.now.to_i,
        currency: "COP",
        payment_method: "Contra entrega",        
        timestamp: "#{Time.now.to_i}", 
        elements: elements,
        summary: {
          subtotal: total,
          shipping_cost: 0,
          total_tax: 0,
          total_cost: total
        }
      }
    }
    })


    # ENVIAR CORREO

    user.step = "end"
    user.save

  elsif user.step == "look"
    user.cart["look"] = message.text

    message.reply(text: "Un numero de telefono por si acaso")

    user.step = "phone"
    user.save
  elsif user.step == 'where'

    user.cart["where"] = message.text

    message.reply(text: "Como reconocerte ?")

    user.step = "look"
    user.save

  else 

    message.typing_on
    message.reply(text: 'no entiendo :(')
  end
end

Bot.on :postback do |postback|
  user = User.find_or_create_by!(messenger_id: postback.sender['id'])

  if postback.payload == 'NO'

    postback.reply(text: 'Donde esta ubicado ?')

    user.step = 'where'
    user.save

  end

  if user.step == "product"
    user.cart["product"] = [] unless user.cart["product"]
    user.cart["product"] << postback.payload

    postback.reply({
      attachment: {
        type: "template",
        payload: {
          template_type: "button",
          text: "Quiere pedir mas ?",
          buttons: [
            {
              type: "postback",
              title: "Si",
              payload: "SI"
            },
            {
              type: "postback",
              title: "No",
              payload: "NO"
            }
          ]
        }
      }
    })

    user.save

  end

  if user.step == "category"
    category = Category.find(postback.payload)

    elements = category.products.all.map do |product|
           {
            title: product.name,
            #image_url: "https://petersfancybrownhats.com/company_image.png",
            subtitle: "We\'ve got the right hat for everyone.",
            buttons: [
              {
                title: "escoger",
                type: "postback",
                payload: product.id
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

    user.step = "product"
    user.save
  end

  if user.step == "choose"
    shop = Shop.find(postback.payload)
    user.shop = shop
    user.save!

    postback.reply(text: 'De qué te antojas hoy ?')

    elements = user.shop.categories.all.map do |category|
           {
            title: category.name,
            #image_url: "https://petersfancybrownhats.com/company_image.png",
            subtitle: "We\'ve got the right hat for everyone.",
            buttons: [
              {
                title: "escoger",
                type: "postback",
                payload: category.id
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

    user.step = "category"
    user.save

  end

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
                title: "escoger",
                type: "postback",
                payload: shop.id
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

    user.step = "choose"
    user.save

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
