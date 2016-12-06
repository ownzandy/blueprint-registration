module SemestersHelper
  def make_semester_viewable(sem)
    sem.season.capitalize + " " + sem.year.to_s
  end
end