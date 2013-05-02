require "smsru/version"
require "httparty"

module Smsru
  include I18n
  include HTTParty

  SEND_SMS = "http://sms.ru/sms/send"
  STATUS_SMS = "http://sms.ru/sms/status"
  COST_SMS = "http://sms.ru/sms/cost"
  BALANACE = "http://sms.ru/my/balance"
  LIMIT = "http://sms.ru/my/limit"
  SENDERS = "http://sms.ru/my/senders"
  GET_STOPLIST = "http://sms.ru/stoplist/get"
  ADD_STOPLIST = "http://sms.ru/stoplist/add"
  DEL_STOPLIST = "http://sms.ru/stoplist/del"

  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def smsru_api_id(api_id)
      @api_id ||= api_id
    end

    # Public: Sending one or many sms
    #
    # sms        - The array or hash with sms's text and sms's number
    # from       - The string number of sender phone number
    # time       - The integer Unix timestmamp time in which will be sent sms, not more than 7 days
    # translit   - The integer, 1 for translit sms message
    # test       - The integer, 1 for test responces
    #
    # Examples
    #
    #   sms = {number: "+375336006060", message: "hello"}
    #   or many sms'es
    #   sms = [{number: "+375336006060", message: "hello"}, {number: "+375336006062", message: "hello2"} ... ]
    #
    #   send_sms(sms: sms)
    #   # => { :balance=>"balance=0",
    #          :status_code=>"100",
    #          :smses_ids=>[{:number=>375336006015, :id=>"201318-205295"}]}
    #
    # Returns the hash with reposnce
    # => balance - account balance
    # => status_code - code status for sended sms, 100 - OK
    # => smses_ids - array of sms number and sms id if check his status
    def send_sms(sms: [], from: '', time: 0, translit: 0, test: 0)
      options = query_for_send_sms(sms, from, time, translit, test)
      responce = HTTParty.get(SEND_SMS, options)

      send_sms_parse_responce responce.body, sms
    end

    # Public: Check sms's cost
    #
    # to      - The string mobile number for sending sms
    # message - The string message for sending sms
    #
    # Examples
    #
    #   cost_sms("375336006060", "Hello")
    # => {:status_code=>"100", :sms_cost=>"10", :sms_length=>"1"}
    #
    # Returns the hash with reposnce
    # => status_code - code status for request, 100 - the request is successful
    # => sms_cost    - sms price
    # => sms_length  - the number of messages to be sent
    def cost_sms(to, message)
      options = {query: {api_id: @api_id, to: to, text: message}}
      responce = HTTParty.get(COST_SMS, options)

      cost_sms_parse_responce responce.body
    end

    # Public: Check sms's status
    #
    # to - The string sms's id, obtained by sending a message
    #
    # Examples
    #
    #   status_sms("201318-205295")
    # => {:status_code=>"100"}
    #
    # Returns the hash with sms's status code
    # => status_code - code status for sms, 102 - sms in transit
    def status_sms(sms_id)
      options = {query: {api_id: @api_id, id: sms_id}}
      responce = HTTParty.get(STATUS_SMS, options)

      parse_status_code responce.body
    end

    # Public: Return account balance
    #
    # Examples
    #
    #   balance
    # => {:status_code=>"100", :balance=>"0"}
    #
    # Returns the hash with account balance and request query status
    #
    # => status_code - code status for request, 100 - the request is successful
    # => balance - the balance in the account
    def balance
      options = {query: {api_id: @api_id}}
      responce = HTTParty.get(BALANACE, options)

      balance_parse_responce responce.body
    end

    # Public: Return limit for senging smses
    #
    # Examples
    #
    #   limit
    # => {:status_code=>"100", :day_limit=>"10", :send_today=>"0"}
    #
    # Returns the hash with limit for daily sendgins sms and request query status
    #
    # => status_code - the code status for request, 100 - the request is successful
    # => day_limit - the count of sms per day
    # => send_today - the count sms'es sended today
    def limit
      options = {query: {api_id: @api_id}}
      responce = HTTParty.get(LIMIT, options)

      limit_parse_responce responce.body
    end

    # Public: Returns all the mobile numbers that were senders
    #
    # Examples
    #
    #   senders
    # => {:status_code=>"100", :senders=>["375336006015"]}
    #
    # Returns the hash with array of all senders and request query status
    #
    # => status_code - the code status for request, 100 - the request is successful
    # => senders - the array of all senders
    def senders
      options = {query: {api_id: @api_id}}
      responce = HTTParty.get(SENDERS, options)

      senders_parse_responce responce.body
    end

    # Public: Add mobile number to stop list
    #
    # number - The string, mobile number for sending sms
    # message - The stting, notice for add to stop list
    #
    # Examples
    #
    #   add_to_stoplist("375336006015", "Spy should be banned")
    # => {:status_code=>"100"}
    #
    # Returns the hash with status code of operation
    #
    # => status_code - 100 the mobile numer add to stop list
    def add_to_stoplist(number, message)
      options = {query: {api_id: @api_id}.merge(stoplist_phone: number, stoplist_text: message)}
      responce = HTTParty.get(ADD_STOPLIST, options)

      parse_status_code responce.body
    end

    # Public: Remove mobile number from stop list
    #
    # number - The string, mobile number for removing from stop list
    #
    # Examples
    #
    #   remove_from_stoplist("375336006015")
    # => {:status_code=>"100"}
    #
    # Returns the hash with status code of operation
    #
    # => status_code - 100 the mobile numer remove from stop list
    def remove_from_stoplist(number)
      options = {query: {api_id: @api_id}.merge(stoplist_phone: number)}
      responce = HTTParty.get(DEL_STOPLIST, options)

      parse_status_code responce.body
    end

    # Public: Returns all mobile number from stop list
    #
    # number - The string, mobile number for removing from stop list
    #
    # Examples
    #
    #   get_stoplist
    # => {:status_code=>"100"}
    #
    # Returns the hash with status code of request and array of stoplist
    #
    # => {:status_code=>"100",
    #     :stoplist=>
    #       [{:number=>"3753360253523", :notice=>"spamer"}...] }
    # => status_code - the code status for request, 100 - the request is successful
    # => stoplist - array of all mobile numbers from stoplist, number- phone number, notice- comment with add number to stoplist
    def get_stoplist
      options = {query: {api_id: @api_id}}
      responce = HTTParty.get(GET_STOPLIST, options)

      get_stoplist_parse_responce responce.body
    end

    private

    def get_stoplist_parse_responce(responce)
      if responce && responce.split("\n").count > 0
        parsed_responce = parse_status_code responce
        responces = responce.split("\n")

        if parsed_responce[:status_code] == "100"
          if responces.count > 1
            stoplists = responces.slice(1..-1)

            parsed_stoplist = stoplists.map do |phone_number|
              number = phone_number.split(";")
              number << " " if number.count == 1
              {number: number.first, notice: number.last}
            end

            parsed_responce.merge({stoplist: parsed_stoplist})
          else
            parsed_responce.merge({stoplist: []})
          end
        end
      else
        responce
      end
    end

    def senders_parse_responce(responce)
      if responce && responce.split("\n").count > 0
        parsed_responce = parse_status_code responce
        responces = responce.split("\n")

        if parsed_responce[:status_code] == "100"
          parsed_responce.merge({senders: responces.slice(1..-1)})
        end
      else
        responce
      end
    end

    def limit_parse_responce(responce)
      if responce && responce.split("\n").count > 0
        parsed_responce = parse_status_code responce
        responces = responce.split("\n")

        if parsed_responce[:status_code] == "100"
          parsed_responce.merge({day_limit: responces.slice(1), send_today: responces.slice(2)})
        end
      else
        responce
      end
    end

    def balance_parse_responce(responce)
      if responce && responce.split("\n").count > 0
        parsed_responce = parse_status_code responce
        responces = responce.split("\n")

        if parsed_responce[:status_code] == "100"
          parsed_responce.merge({balance: responces.slice(1)})
        end
      else
        responce
      end
    end

    def cost_sms_parse_responce(responce)
      if responce && responce.split("\n").count > 0
        parsed_responce = parse_status_code responce
        responces = responce.split("\n")

        if parsed_responce[:status_code] == "100"
          parsed_responce.merge({sms_cost: responces.slice(1), sms_length: responces.slice(2)})
        end
      else
        responce
      end
    end

    def parse_status_code(responce)
      if responce && responce.split("\n").count > 0
        {status_code: responce.split("\n").first}
      else
        {status_code: nil}
      end
    end

    def send_sms_parse_responce(responce, sms)
      if responce && responce.split("\n").count > 2
        responces = responce.split("\n")

        balance = responces.pop
        status_code = responces.slice!(0)
        {
          balance: balance,
          status_code: status_code,
          smses_ids: [sms].flatten.map.with_index { |sms, index| {number: sms[:number], id: responces[index]} }
        }
      end
    end

    def query_for_send_sms(sms, from, time, translit, test)
      if Array === sms
        max = sms.count < 100 ? sms.count : 100
        smses_query = {}

        sms.slice!(0...max).each do |sms|
          smses_query.merge!("multi[#{sms[:number]}]" => sms[:message])
        end

        send_sms(sms: sms, from: from, time: time, translit: translit, test: test) if sms.count > 0
      elsif Hash === sms
        smses_query = {to: sms[:number], text: sms[:message]}
      end

      options = {query: {api_id: @api_id, translit: translit, time: time, test: test}.merge(smses_query)}
    end
  end
end