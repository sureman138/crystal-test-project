require "json"

class Bike
    include JSON::Serializable
  
    property name : String
    property description : String
    property price : Float64 | String
    property created_at : Time?
  
    def initialize(@name : String, @description : String, @price : Float64 | String, @created_at : Time?)
    end
  end