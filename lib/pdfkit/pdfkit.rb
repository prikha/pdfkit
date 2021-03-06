class PDFKit

  class NoExecutableError < StandardError
    def initialize
      msg  = "No wkhtmltopdf executable found at #{PDFKit.configuration.wkhtmltopdf}\n"
      msg << ">> Please install wkhtmltopdf - https://github.com/jdpace/PDFKit/wiki/Installing-WKHTMLTOPDF"
      super(msg)
    end
  end

  class ImproperSourceError < StandardError
    def initialize(msg)
      super("Improper Source: #{msg}")
    end
  end

  attr_accessor :source, :stylesheets
  attr_reader :options

  def initialize(url_file_or_html, options = {})
    @source = Source.new(url_file_or_html)

    @stylesheets = []

    @options = PDFKit.configuration.default_options.merge(options)
    #add default options here to clarify the walkthrough
    #@options[:use_xserver]= true
    #@options[:quiet]= true
    #force page section to be created
    @options[:page]={}
    #fetch page-defined options into page section options
    @options[:page].merge! find_options_in_meta(url_file_or_html) unless source.url?
    #split global options from nested to merge then back but in different order
    buffer=@options.select{|k,v| !v.is_a?(Hash)}
    special=@options.select{|k,v| v.is_a?(Hash)}
    #should preccess every portion of options separately, but for now this will go
    @options=buffer.merge(special)
    #proccess the whole @options mega-hash
    @options = normalize_options(@options)

    raise NoExecutableError.new unless File.exists?(PDFKit.configuration.wkhtmltopdf)
  end

  def command(path = nil)
    args = [executable]
    #flatten first level
    args += @options.to_a.flatten.compact
    #flatten nested hashes
    args.map!{|e| e.is_a?(Hash) ? e.to_a.flatten.compact : e }
    args.flatten!
    #remove overloaded elements
    args.delete_if{|e| e=="--input"}
    #add source to page section
    if @source.html?
      args.insert(args.find_index("page")+1, '-') # Get HTML from stdin
    else
      args.insert(args.find_index("page")+1, @source.to_s)
    end
    #add output option
    args << (path || '-') # Write to file or stdout
    #wrap strings into quotes
    args.map {|arg| %Q{"#{arg.gsub('"', '\"')}"}}

  end

  def executable
    default = PDFKit.configuration.wkhtmltopdf
    return default if default !~ /^\// # its not a path, so nothing we can do
    if File.exist?(default)
      default
    else
      default.split('/').last
    end
  end

  def to_pdf(path=nil)
    append_stylesheets

    args = command(path)
    invoke = args.join(' ')

    result = IO.popen(invoke, "wb+") do |pdf|
      pdf.puts(@source.to_s) if @source.html?
      pdf.close_write
      pdf.gets(nil)
    end
    result = File.read(path) if path

    raise "command failed: #{invoke}" if result.to_s.strip.empty?
    return result
  end

  def to_file(path)
    self.to_pdf(path)
    File.new(path)
  end

  protected

    def find_options_in_meta(content)
      # Read file if content is a File
      content = content.read if content.is_a?(File)

      found = {}
      content.scan(/<meta [^>]*>/) do |meta|
        if meta.match(/name=["']#{PDFKit.configuration.meta_tag_prefix}/)
          name = meta.scan(/name=["']#{PDFKit.configuration.meta_tag_prefix}([^"']*)/)[0][0]
          found[name.to_sym] = meta.scan(/content=["']([^"']*)/)[0][0]
        end
      end

      found
    end

    def style_tag_for(stylesheet)
      "<style>#{File.read(stylesheet)}</style>"
    end

    def append_stylesheets
      raise ImproperSourceError.new('Stylesheets may only be added to an HTML source') if stylesheets.any? && !@source.html?

      stylesheets.each do |stylesheet|
        if @source.to_s.match(/<\/head>/)
          @source = Source.new(@source.to_s.gsub(/(<\/head>)/, style_tag_for(stylesheet)+'\1'))
        else
          @source.to_s.insert(0, style_tag_for(stylesheet))
        end
      end
    end

    def normalize_options(options)
      normalized_options = {}
      #don`t add '--' into base sections page toc and cover but
      #keep on normalizing every portion of data
      options.each do |key, value|
        next if !value
        if value.is_a?(Hash)
          normalized_key = "#{normalize_arg key}"
          normalized_options[normalized_key]=normalize_options(value)
        else
          normalized_key = "--#{normalize_arg key}"
          normalized_options[normalized_key] = normalize_value(value)
        end
      end
      normalized_options
    end

    def normalize_arg(arg)
      arg.to_s.downcase.gsub(/[^a-z0-9]/,'-')
    end

    def normalize_value(value)
      case value
      when TrueClass
        nil
      else
        value.to_s
      end
    end

end
