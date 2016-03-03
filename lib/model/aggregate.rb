module Gorilla

  class Aggregate
    include Mongoid::Document
    
    field :organisation_id, type: Symbol
    field :total, type: BigDecimal, default: ->{ 0 }
    field :total_year, type: BigDecimal, default: ->{ 0 }
    field :total_month, type: BigDecimal, default: ->{ 0 }
    field :total_week, type: BigDecimal, default: ->{ 0 }
    field :total_day, type: BigDecimal, default: ->{ 0 }
    
    field :current_day, type: Integer
    field :current_week, type: Integer
    field :current_month, type: Integer
    field :current_year, type: Integer
    
    def self.make(organisation_id)
      entity = self.new
      entity.organisation_id = organisation_id
      entity.current_day = Time.now.strftime('%u').to_i
      entity.current_week = Time.now.strftime('%W').to_i
      entity.current_month = Time.now.strftime('%-m').to_i
      entity.current_year = Time.now.strftime('%Y').to_i
      entity
    end
    
    def to_hash
      {
        :total => self.total,
        :total_year => self.total_year,
        :total_month => self.total_month,
        :total_week => self.total_week,
        :total_day => self.total_day        
      }
    end
    
    def add_amount(amount_string)
      amount = BigDecimal.new(amount_string)
      current_day = Time.now.strftime('%u').to_i
      current_week = Time.now.strftime('%W').to_i
      current_month = Time.now.strftime('%-m').to_i
      current_year = Time.now.strftime('%Y').to_i
      
      if (current_day > self.current_day or current_day < self.current_day) and self.total_day != 0
        self.total_day = amount
        self.current_day = current_day
      else
        self.total_day += amount
      end
      if (current_week > self.current_week or current_week < self.current_week) and self.total_week != 0
        self.total_week = amount
        self.current_week = current_week
      else
        self.total_week += amount
      end
      if (current_month > self.current_month or current_month < self.current_month) and self.total_month != 0
        self.total_month = amount
        self.current_month = current_month
      else
        self.total_month += amount
      end      
      if current_year > self.current_year and self.total_year != 0
        self.total_year = amount
        self.current_year = current_year
      else
        self.total_year += amount
      end
      
      self.total += amount
      
      self
    end
    
  end
  
end
