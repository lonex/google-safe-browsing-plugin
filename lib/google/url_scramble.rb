module Google
  module UrlScramble
    extend self
    
    # url is canonicalized url
    def gen url
      m = Google::UrlCanonicalizer::URL_REGEX.match(url)
      return [[], []] if m.nil?
      protocol, host, port, dir, query = m[:protocol], m[:host], m[:port], m[:dir], m[:query]
      return [[], []] if host.nil?

      urls = []
      hosts, paths = [], []

      hosts << host
      if /[^\d.]/ =~ host
        host_segments = host.split('.')
        host_segments = host_segments[-6..-1] if host_segments.size >= 6
        h = host_segments.shift
        while !h.nil? && host_segments.size > 1 && hosts.size <= 5
          hosts << host_segments.join('.')
          h = host_segments.shift
        end
        host_keys = hosts.select {|x| x.count(".") == 2 or x.count(".") == 1}.map{|x| x+'/'}
      else
        host_keys = hosts.map{|x| x+'/'}
      end
      
      dir = dir.to_s.sub(/\A\//, '') # remove the leading slash
      paths << ('/' << dir)
      paths << ('/' << dir << query.to_s) unless query.blank?
      path_segments = dir.split('/')
      paths << '/'
      count = 0; tmp_path = ''
      while !(p = path_segments.shift).nil? && count <= 3
        tmp_path += ('/' << p)
        paths << tmp_path
        count += 1
      end
      paths.uniq!
      
      (urls = []).tap do
        hosts.each do |h|
          paths.each do |p|
            urls << h + p
          end
        end
      end
      
      [host_keys, urls]
    end
    
  end
end