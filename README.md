#This is a fork of original [pdfkit](http://github.com/pdfkit/pdfkit) but is rewritten to work with newer versions of *wkhtmltopdf* binary
# PDFKit

Create PDFs using plain old HTML+CSS. Uses [wkhtmltopdf](http://github.com/antialize/wkhtmltopdf) on the back-end which renders HTML using Webkit.
Be aware of using versions compatible with new options described in [documentation](http://madalgo.au.dk/~jakobt/wkhtmltoxdoc/wkhtmltopdf_0.10.0_rc2-doc.html)
Those versions are (as far as i know) 0.10.2 and higher
## Install

### PDFKit
```sh
    # Gemfile
    gem 'pdfkit', :git=>'git://github.com/prikha/pdfkit.git'
```
### Get Wkhtmltopdf binary version 0.10.2 and higher

* Take static build(recommended) or build it yourself:

    <https://github.com/pdfkit/pdfkit/wiki/Installing-WKHTMLTOPDF>
    ***CHECK THE SUPPORTED VERSIONS ABOVE***

*Note:* Check your version by typing ```sh wkhtmltopdf --version ```.

## Usage
```ruby
    # PDFKit.new takes the HTML and any options for wkhtmltopdf
    # run `wkhtmltopdf --extended-help` for a full list of options
    kit = PDFKit.new(html, :page_size => 'Letter')
    kit.stylesheets << '/path/to/css/file'

    # Get an inline PDF
    pdf = kit.to_pdf

    # Save the PDF to a file
    file = kit.to_file('/path/to/save/pdf')

    # PDFKit.new can optionally accept a URL or a File.
    # Stylesheets can not be added when source is provided as a URL of File.
    kit = PDFKit.new('http://google.com')
    kit = PDFKit.new(File.new('/path/to/html'))

    # Add any kind of option through meta tags
    PDFKit.new('<html><head><meta name="pdfkit-page_size" content="Letter")
```
## Configuration

If you're on Windows or you installed wkhtmltopdf by hand to a location other than /usr/local/bin you will need to tell PDFKit where the binary is. You can configure PDFKit like so:
```ruby
    # config/initializers/pdfkit.rb
    PDFKit.configure do |config|
       config.wkhtmltopdf = '/path/to/wkhtmltopdf'
       config.default_options = {
        #here goes global options
        :print_media_type => true
        :page_size     => 'Letter',
        :margin_top    => '0.7in',
        :margin_right  => '0.5in',
        :margin_bottom => '0.7in',
        :margin_left   => '0.5in',
        :footer_spacing  =>   5,
        :header_spacing  =>   5,
        :page=>{
                #here you can specifiy page-specific options
                #every option specified inside html-document
                #inside meta-tags would go here
                }
        :cover=>{
                :input=>cover
                },
        :toc => {
                :toc_header_text=>"Custom TOC header",
                :disable_toc_links=> true
                 }
       }
       config.root_url = "http://localhost" # Use only if your external hostname is unavailable on the server.
    end
```

## Middleware

PDFKit comes with a middleware that allows users to get a PDF view of any page on your site by appending .pdf to the URL.

### Middleware Setup

**Non-Rails Rack apps**
```ruby
    # in config.ru
    require 'pdfkit'
    use PDFKit::Middleware
```
**Rails apps**
```ruby

    # in application.rb(Rails3) or environment.rb(Rails2)
    require 'pdfkit'
    config.middleware.use PDFKit::Middleware
```
**With PDFKit options**
```ruby
    # options will be passed to PDFKit.new
    config.middleware.use PDFKit::Middleware, :print_media_type => true
```
**With conditions to limit routes that can be generated in pdf**
```ruby
    # conditions can be regexps (either one or an array)
    config.middleware.use PDFKit::Middleware, {}, :only => %r[^/public]
    config.middleware.use PDFKit::Middleware, {}, :only => [%r[^/invoice], %r[^/public]]

    # conditions can be strings (either one or an array)
    config.middleware.use PDFKit::Middleware, {}, :only => '/public'
    config.middleware.use PDFKit::Middleware, {}, :only => ['/invoice', '/public']

    # conditions can be regexps (either one or an array)
    config.middleware.use PDFKit::Middleware, {}, :except => [%r[^/prawn], %r[^/secret]]

    # conditions can be strings (either one or an array)
    config.middleware.use PDFKit::Middleware, {}, :except => ['/secret']
```
## Troubleshooting

*  **Single thread issue:** In development environments it is common to run a
   single server process. This can cause issues when rendering your pdf
   requires wkhtmltopdf to hit your server again (for images, js, css).
   This is because the resource requests will get blocked by the initial
   request and the initial request will be waiting on the resource
   requests causing a deadlock.

   This is usually not an issue in a production environment. To get
   around this issue you may want to run a server with multiple workers
   like Passenger or try to embed your resources within your HTML to
   avoid extra HTTP requests.

*  **Resources aren't included in the PDF:** Images, CSS, or JavaScript
   does not seem to be downloading correctly in the PDF. This is due
   to the fact that wkhtmltopdf does not know where to find those files.
   Make sure you are using absolute paths (start with forward slash) to
   your resources. If you are using PDFKit to generate PDFs from a raw
   HTML source make sure you use complete paths (either file paths or
   urls including the domain). In restrictive server environments the
   root_url configuration may be what you are looking for change your
   asset host.

*  **Mangled output in the browser:** Be sure that your HTTP response
   headers specify "Content-Type: application/pdf" 

## Note on Patches/Pull Requests

* Any help on issues-fighting(or finding) and testing is highly appreciated

## Copyright

Fork by Sergey Prikhodko originally developed by Jared Pace Copyright (c) 2010. See LICENSE for details.
