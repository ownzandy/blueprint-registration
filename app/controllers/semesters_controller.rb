class SemestersController < ApplicationController

	def index
		@semesters = Semester.all
		render json: @semesters.map{|sem| {:semester => {:season => sem.season, :year => sem.year, :id => sem.id,
				       :events => sem.events.map{|event| {:event_type => event.event_type}}}}}
		end

	def display
		@semesters = Semester.all
	end

	def create
		@semester = Semester.new(semester_params)
		@semester.save!
		redirect_to :back
	end

	def semester_params
		params.require(:semester).permit(:season, :year)
	end

end
