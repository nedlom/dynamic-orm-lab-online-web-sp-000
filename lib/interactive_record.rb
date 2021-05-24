require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord
  
  def self.table_name
    self.to_s.downcase.pluralize
  end
  
  def self.column_names
    sql = "PRAGMA table_info('#{self.table_name}')"
    DB[:conn].execute(sql).map do |key|
      key["name"]
    end
  end
  
  def initialize(options={})
    options.each do |key, value|
      self.send("#{key}=", value)
    end
  end
  
  def table_name_for_insert
    self.class.table_name
  end
  
  def col_names_for_insert
    self.class.column_names.select do |col|
      col != "id"
    end.join(", ")
  end
  
  def values_for_insert
    self.class.column_names.map do |col|
      "'#{send(col)}'" if !send(col).nil?
    end.compact.join(", ")
  end
  
  def save
    sql = <<-SQL
      INSERT INTO #{table_name_for_insert} (#{col_names_for_insert})
      VALUES (#{values_for_insert})
    SQL
    DB[:conn].execute(sql)
    self.id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end
  
  def self.find_by_name(name)
    sql = <<-SQL 
      SELECT * FROM #{self.table_name}
      WHERE name = ?
      SQL
    DB[:conn].execute(sql, name)
  end
  
  def self.find_by(name: nil, grade: nil)
    sql = <<-SQL
      SELECT * FROM #{self.table_name}
      WHERE name = ? OR grade = ?
    SQL
    DB[:conn].execute(sql, name, grade)
  end
end