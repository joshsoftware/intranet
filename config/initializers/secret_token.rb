# Be sure to restart your server when you modify this file.

# Your secret key is used for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!

# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
# You can use `rake secret` to generate a secure secret key.

# Make sure your secret_key_base is kept private
# if you're sharing your code publicly. Need to push these to git
Intranet::Application.config.secret_key_base = 'c0d8496bcd86ac0245af7c2276eef401d39dcb049326d6a77452c5b313e7a5ca727cb034f27a555b8d39e3d0776bf3933b7ab66f6712750193142f4e269f80ff'
