
class Album
	attr_reader :name, :price, :image_url
	def initialize(name, price, image_url)
		@name = name
		@price = price
		@image_url = image_url
	end
end