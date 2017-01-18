require 'better_html/better_erb/implementation'
require 'better_html/better_erb/validated_output_buffer'

class BetterHtml::BetterErb
  cattr_accessor :content_types
  self.content_types = {
    'html.erb' => BetterHtml::BetterErb::Implementation
  }

  def self.prepend!
    ActionView::Template::Handlers::ERB.prepend(ConditionalImplementation)
  end

  private

  module ConditionalImplementation

    def call(template)
      generate(template)
    end

    private

    def generate(template)
      # First, convert to BINARY, so in case the encoding is
      # wrong, we can still find an encoding tag
      # (<%# encoding %>) inside the String using a regular
      # expression

      filename = template.identifier.split("/").last
      exts = filename.split(".")
      exts = exts[1..exts.length].join(".")
      puts "[GENERATE] #{template.identifier} #{exts.inspect}"
      template_source = template.source.dup.force_encoding(Encoding::ASCII_8BIT)

      erb = template_source.gsub(ActionView::Template::Handlers::ERB::ENCODING_TAG, '')
      encoding = $2

      erb.force_encoding valid_encoding(template.source.dup, encoding)

      # Always make sure we return a String in the default_internal
      erb.encode!

      klass = BetterHtml::BetterErb.content_types[exts]
      klass ||= self.class.erb_implementation

      generator = klass.new(
        erb,
        :escape => (self.class.escape_whitelist.include? template.type),
        :trim => (self.class.erb_trim_mode == "-")
      )
      generator.validate!
      generator.src
    end
  end
end
