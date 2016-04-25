module Gorilla

  class PaymentAggregate
    include Mongoid::Document

    field :total, type: BigDecimal, default: ->{ 0 }
    field :total_year, type: BigDecimal, default: ->{ 0 }
    field :total_month, type: BigDecimal, default: ->{ 0 }
    field :total_week, type: BigDecimal, default: ->{ 0 }
    field :total_day, type: BigDecimal, default: ->{ 0 }
    field :total_transactions, type: Integer, default: -> {0}

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
        :total_amount => self.total,
        :total_amount_year => self.total_year,
        :total_amount_month => self.total_month,
        :total_amount_week => self.total_week,
        :total_amount_day => self.total_day,
        :total_transactions => self.total_transactions
      }
    end

    def add_amount(amount_string, currency)
      amount = BigDecimal.new(amount_string)
      if currency == "€"
        amount = amount * 9
      end
      current_day = Time.now.strftime('%u').to_i
      current_week = Time.now.strftime('%W').to_i
      current_month = Time.now.strftime('%-m').to_i
      current_year = Time.now.strftime('%Y').to_i
      self.total_transactions += 1

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
