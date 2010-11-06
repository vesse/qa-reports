module DeviseRegisterationConfig
  URL_TOKEN = (Rails.env.production? || Rails.env.staging?) ?
          File.read(File.join(Rails.root, "config", "registeration_token")) :
          ""
end