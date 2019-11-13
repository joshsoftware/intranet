class VPN
    BASE_URL = "https://vpn.joshsoftware.com/api"

    def register(email, password)
        params = {
            email: email,
            user: email,
            password: password
        }
        Rails.logger.info("Register VPN Params email: #{email}")
        response = RestClient.post(register_url, params.to_json)
        success = response.code == 200 ? true : false
        {success: success, data: response.body}
    rescue Exception => e
        Rails.logger.info("Register VPN Exception #{e.message}")
        {success: false}
    end

    def revoke(user)
        params = {
            user: user
        }
        Rails.logger.info("Revoke Params #{params.to_json}")
        response = RestClient.post(revoke_url, params.to_json)
        Rails.logger.info("Revoke Response #{response.body}")
        result = JSON.parse(response.body)
        success = (result["status"] == "Success") ? true : false
        { success: success, data: response.body }
    rescue Exception => e
        Rails.logger.info("Revoke VPN Exception #{e.message}")
        { success: false }
    end

    def register_url
        "#{BASE_URL}/register"
    end

    def revoke_url
        "#{BASE_URL}/revoke"
    end
end