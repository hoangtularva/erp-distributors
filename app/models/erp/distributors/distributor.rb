module Erp::Distributors
  class Distributor < ApplicationRecord

    belongs_to :creator, class_name: 'Erp::User'
    mount_uploader :image, Erp::Distributors::DistributorImageUploader

    validates :address, :open_time, :latitude, :longitude, presence: true
    validates :name, uniqueness: true, presence: true

    validates :image, allow_blank: true, format: {
			with: %r{\.(gif|jpg|png)\Z}i,
			message: 'URL hình ảnh phải có định dạng: GIF, JPG hoặc PNG.'
		}

    # Filters
    def self.filter(query, params)
      params = params.to_unsafe_hash
      and_conds = []

      # show archived items condition - default: false
      show_archived = false

      # Filters
      def self.filter(query, params)
        params = params.to_unsafe_hash
        and_conds = []

        # show archived items condition - default: false
        show_archived = false

        #filters
        if params["filters"].present?
          params["filters"].each do |ft|
            or_conds = []
            ft[1].each do |cond|
              # in case filter is show archived
              if cond[1]["name"] == 'show_archived'
                # show archived items
                show_archived = true
              else
                or_conds << "#{cond[1]["name"]} = '#{cond[1]["value"]}'"
              end
            end
            and_conds << '('+or_conds.join(' OR ')+')' if !or_conds.empty?
          end
        end

        #keywords
        if params["keywords"].present?
          params["keywords"].each do |kw|
            or_conds = []
            kw[1].each do |cond|
              or_conds << "LOWER(#{cond[1]["name"]}) LIKE '%#{cond[1]["value"].downcase.strip}%'"
            end
            and_conds << '('+or_conds.join(' OR ')+')'
          end
        end

        # join with users table for search creator
        query = query.joins(:creator)

        # showing archived items if show_archived is not true
        query = query.where(archived: false) if show_archived == false

        query = query.where(and_conds.join(' AND ')) if !and_conds.empty?

        return query
      end
    end

    # data for dataselect ajax
    def self.dataselect(keyword='')
      query = self.all

      if keyword.present?
        keyword = keyword.strip.downcase
        query = query.where('LOWER(name) LIKE ?', "%#{keyword}%")
      end

      query = query.limit(8).map{|distributor| {value: distributor.id, text: distributor.name} }
    end
    
    def archive
			update_columns(archived: true)
		end

		def unarchive
			update_columns(archived: false)
		end

    def self.archive_all
			update_all(archived: true)
		end

    def self.unarchive_all
			update_all(archived: false)
    end
    
  end
end
