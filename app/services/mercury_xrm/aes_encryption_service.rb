require "openssl"
require "digest/sha2"
require "base64"

class AesEncryptionService

  def self.encrypt_email(email)
    
    clear_text = email

    cipher = OpenSSL::Cipher::AES256.new(:CBC)
    cipher.encrypt

    cipher.key = Base64.decode64("Evrswr+Wljlnz3e9i7EXsbGEuwvcHnRrDR/ooWBiOk4=")
    cipher.iv = Base64.decode64("Hzt9H5jM9KJA+6s/BGbk8Q==")

    # cipher.key = ["12FAECC2BF96963967CF77BD8BB117B1B184BB0BDC1E746B0D1FE8A160623A4E"].pack("H*")
    # cipher.iv =  ["1F3B7D1F98CCF4A240FBAB3F0466E4F1"].pack("H*")

    clearBytes = clear_text.encode("UTF-16LE")
    encrypted = cipher.update(clearBytes)

    encrypted << cipher.final
    puts Base64.encode64(encrypted)

    Base64.encode64(encrypted)    
  end

end

