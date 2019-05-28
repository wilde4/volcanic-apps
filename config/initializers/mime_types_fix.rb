require 'action_dispatch/http/mime_negotiation'
module ActionDispatch
  module Http
    module MimeNegotiation
      def formats
        @env["action_dispatch.request.formats"] ||=
          if parameters[:format]
            Array(Mime[parameters[:format]])
          elsif use_accept_header && valid_accept_header
            accepts
          elsif xhr?
            [Mime::JS]
          else
            [Mime::HTML]
          end.select do |format|
            format.symbol || format.ref == '*/*'
          end
      end
    end
  end
end