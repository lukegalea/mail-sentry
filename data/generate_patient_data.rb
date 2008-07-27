require 'rubygems'
require 'fastercsv'
require 'faker'

class PHIGenerator
  def rand_num( n )
    (0..n).collect { rand(10) }.join
  end

  def mrn() rand_num 6 end
  def healthcard_no() rand_num 9 end
  def first_name() Faker::Name.first_name end
  def last_name() Faker::Name.last_name end

  def generate( n = 400000 )
    FasterCSV.open("patients.csv", "w") do |csv|
      n.times do
        csv << [mrn, first_name, last_name, healthcard_no]
      end
    end
  end
end

PHIGenerator.new.generate
