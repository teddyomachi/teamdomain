# coding: utf-8

require 'openssl'
require 'base64'
require 'const/ssl_const'

module Security
  include Ssl
  # 64byte hashkey generator for spin-nodes
  # spin-nodes are located by 4-tuple
  # => x : number in the same layer
  # => y : layer number
  # => z : x-value of the parent node
  # => v : version number of the node
  def self.hash_key( x, y, z, v )
    r = Random.new(100.0)
    b = x.to_s + '.' + y.to_s + '.' + z.to_s + '.' + v.to_s + r.rand.to_s
    # make 40byte SHA1 string
    OpenSSL::Digest::SHA1.hexdigest b
  end
  
  def self.hash_key_s( seed_string )
    # make 40byte SHA1 string
    r = Random.new(100.0)
    OpenSSL::Digest::SHA1.hexdigest( seed_string  + r.rand.to_s )
  end
  
  # n byte random string generator
  def self.make_padding( n )
    a = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
    Array.new(n) {a[rand(a.size)]}.join
  end
  
  def self.public_key_encrypt rsa_pem, data # => SpinNode.get_root_public_key,  paramshash[:session_id] + vfile_key
    rsa = OpenSSL::PKey::RSA.new rsa_pem
    s = ''
    block_size = 0
    block_size = KEY_SIZE
    #    block_size = ((KEY_SIZE / 8) - 16) / 3
    dlen = data.length # => for UNICODE encoding
    #    pp dlen,block_size
    enc_block_size = block_size
    #    enc_block_size = block_size - 41
    if dlen <= enc_block_size
      s = rsa.public_encrypt data, OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING
      return s
    else
      enclen = dlen
      d_start = 0
      d_length = enc_block_size
      while enclen > 0
        d_length = (enclen < enc_block_size ? enclen : enc_block_size)
        input_s = data[d_start,d_length]
        s += rsa.public_encrypt(input_s, OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING)
        d_start += d_length
        enclen -= d_length
      end
    end
    
    # => data is longer than KEY_SIZE/8
    # => it should be separated into blocks
    #    pp "start block"
    #    d_start = 0
    #    d_length = block_size
    #    while true
    #      if d_start > (dlen -1)
    #        break
    #      end
    #      if (d_start + d_length) > dlen
    #        d_length = dlen - d_start
    #      end
    #      #      printf "(d_start,d_length) = (%d,%d)\n", d_start,d_length
    #      s += rsa.public_encrypt(data[d_start,d_length], OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING)
    #      d_start += block_size
    #    end
    return s
  end # => end of public_key_encode
  
  def self.public_key_encrypt2 rsa_pem, data    # => SpinNode.get_root_public_key,  paramshash[:session_id] + vfile_key
    
    begin
      rsa = OpenSSL::PKey::RSA.new rsa_pem
      s = String.new
      encrypted = String.new
      encrypted_len = Array.new
      encrypted_info = Hash.new
      block_size = 0
      block_size = (KEY_SIZE / 8)
      #    block_size = ((KEY_SIZE / 8) - 16) / 3
      dlen = data.length # => for UNICODE encoding
      #    pp dlen,block_size
      enc_block_size = block_size - 42
      if dlen <= enc_block_size
        encrypted = rsa.public_encrypt data, OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING
        encrypted_len.push(encrypted.length)
      else
        enclen = dlen
        d_start = 0
        d_length = enc_block_size
        while enclen > 0
          d_length = (enclen < enc_block_size ? enclen : enc_block_size)
          input_s = String.new(data[d_start,d_length])
          s = rsa.public_encrypt input_s, OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING
          encrypted += s
          encrypted_len.push(s.length)
          d_start += d_length
          enclen -= d_length
        end
      end
    rescue OpenSSL::PKey::RSAError => exc_rsa
      FileManager.rails_logger(exc_rsa.to_s, LOG_ERROR)
      raise
    rescue => exc_obj
      FileManager.rails_logger(exc_obj.to_s, LOG_ERROR)
      raise
    end
    
    encrypted_info[:length] = encrypted_len
    encrypted_info[:data] = encrypted
    
    return encrypted_info
  end # => end of public_key_encode

  def self.private_key_encrypt rsa_pem, data # => SpinNode.get_root_public_key,  paramshash[:session_id] + vfile_key
    rsa = OpenSSL::PKey::RSA.new rsa_pem
    s = rsa.private_encrypt data
    return s
  end # => end of public_key_encode
  
  def self.rsa_key key_string = nil
    # generate rsa key pair
    if key_string
      r = OpenSSL::PKey::RSA.new key_string
    else
      r = OpenSSL::PKey::RSA.new KEY_SIZE, EXPONENT
    end
    return r
  end
  
  def self.encode_base64 data
    e = Base64.encode64 data
    return e
  end # => end of encode_base64 data
  
  def self.urlsafe_encode_base64 data
    e = Base64.urlsafe_encode64 data
    return e
  end # => end of urlsafe_encode_base64 data
  
  def self.urlsafe_decode_base64 data
    e = Base64.urlsafe_decode64 data
    return e
  end # => end of urlsafe_decode_base64 data
  
  def self.escape_base64 data
    # encode base64 string to %HEX-escape of '+/='
    e = data.gsub("+","%2B").gsub("/","%2F").gsub("=","%3D")
    return e
  end # => end of encode_base64 data
  
  def self.unescape_base64 data
    # decode escaped base64 string with self.escape_base64
    # unescape %HEX-notaion to '+/='
    d = data.gsub("%2B","+").gsub("%2F","/").gsub("%3D","=").gsub(" ","+")
    return d
  end # => end of encode_base64 data
  
  def self.public_key_decrypt rsa_pem, data
    rsa = OpenSSL::PKey::RSA.new rsa_pem
    dec = rsa.public_decrypt data
    return dec
  end # => end of private_key_decrypt_decode64
  
  def self.private_key_decrypt rsa_pem, data
    rsa = OpenSSL::PKey::RSA.new rsa_pem
    dec = ''
    block_size = 0
    block_size = KEY_SIZE / 8
    #    block_size = KEY_SIZE
    dlen = data.length
    if dlen <= block_size
      dec = rsa.private_decrypt data, OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING
      return dec
    end
    
    # => data is longer than KEY_SIZE/8
    # => it should be separated into blocks
    d_start = 0
    d_length = block_size
    while true
      if d_start > (dlen -1)
        break
      end
      if (d_start + d_length) > dlen
        d_length = dlen - d_start
      end
      dec += rsa.private_decrypt(data[d_start,d_length])
      d_start += block_size
    end
    return dec
  end # => end of private_key_decrypt_decode64
  
  def self.public_key_decrypt_decode64 rsa_pem, data64
    d = Base64.decode64 data64
    rsa = OpenSSL::PKey::RSA.new rsa_pem
    dec = rsa.public_decrypt d
    return dec
  end # => end of private_key_decrypt_decode64
  
  def self.private_key_decrypt_decode64 rsa_pem, data64
    d = Base64.decode64 data64
    rsa = OpenSSL::PKey::RSA.new rsa_pem
    dec = rsa.private_decrypt d
    return dec
  end # => end of private_key_decrypt_decode64
  
end
