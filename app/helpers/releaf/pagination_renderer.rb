module Releaf
  module PaginationRenderer
    # This class does the heavy lifting of actually building the pagination
    # links. It is used by +will_paginate+ helper internally.

    # This is used in admin/base/_index.footer view

    class LinkRenderer < WillPaginate::ActionView::LinkRenderer

      def to_html
        html_items = []
        options = ["<div class='pages'><select id='page_select' name='page'>"]
        html = pagination.map do |item|
          unless item.is_a?(Fixnum)
            if item == :gap
              options << send(item)
            else
              html_items << send(item)
            end
          else
            selected = item == current_page ? "selected=selected" : nil
            start_item = item == 1 ? 1 : (item-1) * @collection.per_page + 1
            end_item = item * @collection.per_page
            if end_item > @collection.total_entries
              end_item = @collection.total_entries
            end
            options << "<option value='#{item}' #{selected}>#{start_item} - #{end_item}</option>"
          end
        end
        options << "</select></div>"

        html = [
          html_items[0],
          options.join,
          html_items[1]
        ]

        html = html.join
        @options[:container] ? html_container(html) : html
      end

      protected

      def gap
        text = '&hellip;'
        %(<option value="" class="gap">#{text}</option>)
      end

      def previous_or_next_page(page, text, classname)
        if page
          if classname == 'previous_page'
            link('<i class="icon-chevron-left"></i>', page, :class => classname + ' button')
          else
            link('<i class="icon-chevron-right"></i>', page, :class => classname + ' button')
          end
        else
          if classname == 'previous_page'
            tag(:span, '<i class="icon-chevron-left"></i>', :class => classname + ' button disabled')
          else
            tag(:span, '<i class="icon-chevron-right"></i>', :class => classname + ' button disabled')
          end
        end
      end

      def link(text, target, attributes = {})
        if target.is_a? Fixnum
          attributes[:rel] = rel_value(target)
          target = url(target)
        end
        attributes[:href] = target
        tag(:a, "<span>#{text}</span>", attributes)
      end

    end
  end
end
