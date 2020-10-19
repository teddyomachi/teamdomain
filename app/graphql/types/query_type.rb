module Types
  class QueryType < Types::BaseObject
    # Add root-level fields here.
    # They will be entry points for queries on your schema.

    # TODO: remove me
    field :test_field, String, null: false,
      description: "An example field added by the generator"
    field :fname_field,String,null:true,description:"dummy prop"
    def test_field
      "Hello Teddy!"
    end
    def fname_field
      "Teddy Kiyofuji"
    end
  end
end
