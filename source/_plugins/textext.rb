require 'kramdown'

module Jekyll
  class Site
    alias jekyll_process process
    alias jekyll_render render

    def render
      # sort pages by title
      @pages.sort! do |p1, p2|
        p1 = p1.data['title'] or ''
        p2 = p2.data['title'] or ''
        if p1 == p2
          0
        else
          p1 > p2 ? 1 : -1
        end
      end

      jekyll_render
    end

    def process
      jekyll_process

      from = File.expand_path(config['textext'])
      to   = File.expand_path(config['destination'] + '/textext')
      `ln -s \"#{from}\" \"#{to}\"`
      puts "Created TextExt symlink"

      `make less`
      puts "Updated less"
    end
  end

  # patch the render method so that it doesn't exclude symlinks
  class IncludeTag < Liquid::Tag
    def render(context)
      page_dir = File.dirname(context.environments[0]['page']['url'])
      file     = File.join(context.registers[:site].source, page_dir, @file)

      if not File.exists?(file) then
        file = File.join(context.registers[:site].source, '_includes', @file)
      end

      if not File.exists?(file) then
        return "Include file `#{@file}` not found in `_includes` or `#{page_dir}` directory"
      end

      source  = File.read(file)
      partial = Liquid::Template.parse(source.chomp)

      context.stack do
        partial.render(context)
      end
    end
  end
end

Liquid::Template.register_tag('include', Jekyll::IncludeTag)
