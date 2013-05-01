module Google
  module Error

    class ParserError < StandardError; end
    class InvalidRequest < StandardError; end
    class ServiceUnavailable < StandardError; end
    class NoContent < StandardError; end
    
    class UnknownError < StandardError; end
  end
end