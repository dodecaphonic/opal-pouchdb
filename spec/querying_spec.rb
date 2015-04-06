require "spec_helper"

describe "PouchDB::Database#query" do
  async "maps with a design document " do
    with_new_database do |db|
      ddoc = {
        _id: "_design/by_type",
        views: {
          by_type: {
            map: "function(doc) { if (doc.type == \"Right\") { emit(doc.type); } }"
          }
        }
      }

      %x{
        var ddoc2 = {
          _id: "_design/index",
          views: {
            index: {
              map: function(doc) {
                if (doc.fudge) emit(doc.fudge);
              }.toString()
            }
          }
        };
        #{db.native}.put(ddoc2).then(function() {
          console.log("WATTASDFASF");
          #{db.native}.post({ fudge: "Brown" }).then(function() {
            console.log("2 == WATTASDFASF");
            #{db.native}.query("index").then(function(rs) {
              console.log("=== FUDGE", rs)
            });
          })
        }).catch(function() { console.error("BASDFASDF"); })
      }

      Promise.new
    end
  end
end
