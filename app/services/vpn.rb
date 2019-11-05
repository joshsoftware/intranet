class VPN
    BASE_URL = "https://vpn.joshsoftware.com/api"

    def register(email, password)
        params = {
            email: email,
            user: email,
            password: password
        }
        response = RestClient.post(register_url, params.to_json)
        success = response.code == 200 ? true : false
        {success: success, data: response.body}
    end

    def revoke(user)
        params = {
            user: user
        }
        RestClient.post(register_url, params.to_json)
        success = response.code == 200 ? true : false
        {success: success, data: response.body}
    end

    def register_url
        "#{BASE_URL}/register"
    end

    def revoke_url
        "#{BASE_URL}/revoke"
    end
end