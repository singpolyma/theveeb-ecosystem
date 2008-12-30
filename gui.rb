require 'tk'
require 'tkextlib/tile'
Tk::Tile::__Import_Tile_Widgets__!

afont = TkFont.new :family => 'Helvetica', :size => 12, :weight => 'bold'

TkRoot.new {
	title "Tree"

	search = TkEntry.new {
		pack :side => :top, :fill => 'x', :pady => 20, :padx => 20
	}

	populate = nil
	Tk::Tile::Button.new {
	  text 'Search'
	  command {
			populate.call
		}
	  pack :side => :top, :pady => 10
	}

	desc = TkLabel.new do
		text ''
		wraplength 400
		pack :side => :bottom, :fill => 'x', :pady => 20, :padx => 20
	end

	tree = Tk::Tile::Treeview.new {
		pack :side => :right, :pady => 10
		height 10
		show 'tree'
		column_configure '#0', :width => 500, :anchor => 'w'
		insert '', 'end', :id => :all, :open => true
		bind('ButtonRelease-1') {
			desc.text = "Description:\n#{self.selection[0].text}" rescue ''
		}
	}

	populate = lambda {
			tree.delete :all
			tree.insert '', 'end', :id => :all, :open => true, :text => 'Packages'
			`search/search -dtest.db '#{search.get}'`.split(/\n/).each do |item|
				item = item.split(/\s+/)
				item.shift
				name = item.shift
				version = item.shift
				summary = item.join(' ')
				tree.insert :all, 'end', :text => "#{name} - #{summary}"
			end
	}
	populate.call

}


Tk.mainloop
