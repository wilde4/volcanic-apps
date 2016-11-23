require "openssl"
require "digest/sha2"
require "base64"

class AesEncryptionService

  AES_KEY = "Evrswr+Wljlnz3e9i7EXsbGEuwvcHnRrDR/ooWBiOk4=".freeze
  AES_IV =  "Hzt9H5jM9KJA+6s/BGbk8Q==".freeze

  def self.encrypt_email(email)
    
    clear_text = email

    cipher = OpenSSL::Cipher::AES256.new(:CBC)
    cipher.encrypt

    cipher.key = Base64.decode64( AES_KEY )
    cipher.iv = Base64.decode64( AES_IV )

    clearBytes = clear_text.encode("UTF-16LE")
    encrypted = cipher.update(clearBytes)

    encrypted << cipher.final
    puts Base64.encode64(encrypted)

    Base64.encode64(encrypted)    
  end

end

