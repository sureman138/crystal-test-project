require "json"

class Bike
    include JSON::Serializable
  
    property bike_id : Int32
    property name : String
    property description : String
    property price : Float64
    property created_at : Time?
  
    def initialize(@bike_id : Int32, @name : String, @description : String, @price : Float64, @created_at : Time?)
    end
  end