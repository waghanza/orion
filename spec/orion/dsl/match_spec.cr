require "../../spec_helper"

module Orion::DSL::MatchSpec
  router SampleRouter do
    match "/callable", ->(c : Context) { c.response.print "callable match" }
    match "/block" do |c|
      c.response.print "block match"
    end
    match "/string" do |c|
      "im a string"
    end
    match "/to-match", to: "samples#to_match"
    match "/match-action", controller: SamplesController, action: action_match, helper: "sample_verbose"
  end

  class SamplesController < SampleRouter::BaseController
    def to_match
      response.print "to match"
    end

    def match
      response.print "controller match"
    end

    def action_match
      response.print "action match"
    end
  end

  {% for method in ::Orion::DSL::RequestMethods::METHODS %}
    describe {{ method.downcase }} do
      context "with callable" do
        it "should succeed" do
          response = test_route(SampleRouter.new, :{{ method.downcase.id }}, "/callable")
          response.status_code.should eq 200
          response.body.should eq "callable match"
        end
      end

      context "with a block" do
        it "should succeed" do
          response = test_route(SampleRouter.new, :{{ method.downcase.id }}, "/block")
          response.status_code.should eq 200
          response.body.should eq "block match"
        end
      end

      context "with a string return" do
        it "should succeed" do
          response = test_route(SampleRouter.new, :{{ method.downcase.id }}, "/string")
          response.status_code.should eq 200
          response.body.should eq "im a string\n"
        end
      end

      context "with to" do
        it "should succeed" do
          response = test_route(SampleRouter.new, :{{ method.downcase.id }}, "/to-match")
          response.status_code.should eq 200
          response.body.should eq "to match"
        end
      end

      context "with controller and action" do
        it "should succeed" do
          response = test_route(SampleRouter.new, :{{ method.downcase.id }}, "/match-action")
          response.status_code.should eq 200
          response.body.should eq "action match"
        end
      end
    end
  {% end %}
end
