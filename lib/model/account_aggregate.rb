module Gorilla

  class AccountAggregate
    include Mongoid::Document

    field :total_created, type: BigDecimal, default: ->{ 0 }
    field :total_created_year, type: BigDecimal, default: ->{ 0 }
    field :total_created_month, type: BigDecimal, default: ->{ 0 }
    field :total_created_week, type: BigDecimal, default: ->{ 0 }
    field :total_created_day, type: BigDecimal, default: ->{ 0 }

    field :total_activated, type: BigDecimal, default: ->{ 0 }
    field :total_activated_year, type: BigDecimal, default: ->{ 0 }
    field :total_activated_month, type: BigDecimal, default: ->{ 0 }
    field :total_activated_week, type: BigDecimal, default: ->{ 0 }
    field :total_activated_day, type: BigDecimal, default: ->{ 0 }

    field :current_day, type: Integer
    field :current_week, type: Integer
    field :current_month, type: Integer
    field :current_year, type: Integer
    
    def self.make
      entity = self.new
      entity.current_day = Time.now.strftime('%u').to_i
      entity.current_week = Time.now.strftime('%W').to_i
      entity.current_month = Time.now.strftime('%-m').to_i
      entity.current_year = Time.now.strftime('%Y').to_i
      entity
    end
    
    def to_hash
      {
        :total_created => self.total_created,
        :total_created_year => self.total_created_year,
        :total_created_month => self.total_created_month,
        :total_created_week => self.total_created_week,
        :total_created_day => self.total_created_day,
        :total_activated => self.total_activated,
        :total_activated_year => self.total_activated_year,
        :total_activated_month => self.total_activated_month,
        :total_activated_week => self.total_activated_week,
        :total_activated_day => self.total_activated_day,
      }
    end

    def increment_account_created
      current_day = Time.now.strftime('%u').to_i
      current_week = Time.now.strftime('%W').to_i
      current_month = Time.now.strftime('%-m').to_i
      current_year = Time.now.strftime('%Y').to_i

      if (current_day > self.current_day or current_day < self.current_day) and self.total_created_day != 0
        self.total_created_day = 1
        self.current_day = current_day
      else
        self.total_created_day += 1
      end
      if (current_week > self.current_week or current_week < self.current_week) and self.total_created_week != 0
        self.total_created_week = 1
        self.current_week = current_week
      else
        self.total_created_week += 1
      end
      if (current_month > self.current_month or current_month < self.current_month) and self.total_created_month != 0
        self.total_created_month = 1
        self.current_month = current_month
      else
        self.total_created_month += 1
      end
      if current_year > self.current_year and self.total_created_year != 0
        self.total_created_year = 1
        self.current_year = current_year
      else
        self.total_created_year += 1
      end

      self.total_created += 1

      self
    end

    def increment_account_activated
      current_day = Time.now.strftime('%u').to_i
      current_week = Time.now.strftime('%W').to_i
      current_month = Time.now.strftime('%-m').to_i
      current_year = Time.now.strftime('%Y').to_i

      if (current_day > self.current_day or current_day < self.current_day) and self.total_activated_day != 0
        self.total_activated_day = 1
        self.current_day = current_day
      else
        self.total_activated_day += 1
      end
      if (current_week > self.current_week or current_week < self.current_week) and self.total_activated_week != 0
        self.total_activated_week = 1
        self.current_week = current_week
      else
        self.total_activated_week += 1
      end
      if (current_month > self.current_month or current_month < self.current_month) and self.total_activated_month != 0
        self.total_activated_month = 1
        self.current_month = current_month
      else
        self.total_activated_month += 1
      end
      if current_year > self.current_year and self.total_activated_year != 0
        self.total_activated_year = 1
        self.current_year = current_year
      else
        self.total_activated_year += 1
      end

      self.total_activated += 1

      self
    end

  end
  
end
