
module Google
  module UrlCanonicalizer
    extend self
    
    ANCHOR_REGEX = /(?:#(?:[-\w~!$+|.,*:=]|%[A-Fa-f\d]{2})*)?\b/
    URL_REGEX = /(?<protocol>(?:ht|f)tp(?:s?)\:\/\/|~\/|\/)?(?<user_pwd>\w+:\w+@)?(?<host>((?<sub>[-\w]+\.)+(?<top>com|org|net|gov|mil|biz|info|mobi|name|aero|jobs|museum|travel|[a-z]{2}))|(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}))(?<port>:[\d]{1,5})?(?<dir>(?:(?:\/(?:[-\w~!$+|.=]|%[A-Fa-f\d]{2}|#!)+)+|\/)+|\?|#)?(?<query>(?:\?(?:[-\w~!$+|.,*:]|%[A-Fa-f\d{2}])+=?(?:[-\w~!$+|.,*:=\/]|%[A-Fa-f\d]{2})*)(?:&(?:[-\w~!$+|.,*:]|%[A-Fa-f\d{2}])+=?(?:[-\w~!$+|.,*:=\/]|%[A-Fa-f\d]{2})*)*)*\b/
    
    def apply input_url
      url = input_url.to_s.encode("ASCII-8BIT", :invalid => :replace, :undef => :replace, :replace => '?')
      url = url.gsub(/\s/, '')
      url = url.gsub(ANCHOR_REGEX, '')
      url = unescape(url)
      m = URL_REGEX.match(url.downcase)
      if m
        protocol, host, port, dir, query = m[:protocol], m[:host], m[:port], m[:dir], m[:query]
        protocol = 'http://' if protocol.nil? or protocol == '/'
        host = host.sub(/\A\.*/,'').sub(/\.\z/, '') if host
        dir = dir.sub(/\A\/*/, '').gsub(/\/+/, '/').gsub(/\/\.\//, '/') if dir
        url = protocol << host.to_s << port.to_s << '/' << dir.to_s << query.to_s
      end
      
      url
    end
    
    def unescape url
      unescape = URI.unescape(url)
      while unescape != url
        url = unescape
        unescape = URI.unescape(url)
      end
      URI.escape(unescape)
    end
    
  end
end