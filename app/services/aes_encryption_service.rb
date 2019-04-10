require "openssl"
require "digest/sha2"
require "base64"

class AesEncryptionService

  # AES_KEY_BASE_64 = "Evrswr+Wljlnz3e9i7EXsbGEuwvcHnRrDR/ooWBiOk4=".freeze
  # AES_IV_BASE_64 =  "Hzt9H5jM9KJA+6s/BGbk8Q=="

  # AES_KEY_HEX =     "12FAECC2BF96963967CF77BD8BB117B1B184BB0BDC1E746B0D1FE8A160623A4E".freeze
  # AES_IV_HEX =      "1F3B7D1F98CCF4A240FBAB3F0466E4F1".freeze


  def self.encrypt_email(email, k, c)
    cipher = OpenSSL::Cipher::AES256.new(:CBC)
    cipher.encrypt

    # Base64
    cipher.key = Base64.decode64(k)
    cipher.iv = Base64.decode64(c)

    # Hexadecimal
    # cipher.key = [ AES_KEY_HEX ].pack("H*")
    # cipher.iv =  [ AES_IV_HEX ].pack("H*")

    clearBytes = email.encode("UTF-16LE")
    encrypted = cipher.update(clearBytes)

    encrypted << cipher.final

    Base64.encode64(encrypted)   
  end
end


