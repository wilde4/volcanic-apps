class XmlNodeMissing < StandardError; end
class DataImport::File < ActiveRecord::Base
  belongs_to :profile
  has_many :headers, class_name: 'DataImport::Header', foreign_key: "data_import_file_id", dependent: :destroy
  has_many :lines, class_name: 'DataImport::Line', foreign_key: "data_import_file_id", dependent: :destroy

  validates :model, presence: true
  validates :user_group_id, :uid, presence: true, if: "model == 'user'"

  accepts_nested_attributes_for :headers
  attr_accessor :nodes

  def create_headers(data, xml_nodes)
    case filetype
    when 'csv'
      csv = CSV.parse(data.read, :headers => true)
      if csv.headers.include?(uid)
        csv.headers.each do |header|
          headers.create name: header
        end
      else
        errors.add(:base, 'Unique ID is not included in headers')
        return false
      end
    when 'xml'
      doc = Nokogiri::XML(data)
      post = doc.css(post_mapping).first

      if xml_nodes.include?(uid)
        xml_nodes.each do |node|
          raise XmlNodeMissing, "#{node} not present in provided XML schema" if post.at_css(node).blank?
          headers.create name: node
        end
      else
        errors.add(:base, 'Unique ID is not included in nodes')
        return false
      end
    end
  rescue CSV::MalformedCSVError => e
    errors.add(:base, "Error parsing CSV: #{e}")
    return false
  rescue XmlNodeMissing => e
    errors.add(:base, "Error parsing XML: #{e}")
    return false
  end

  def check_headers(data)
    h1 = CSV.parse(data.read, :headers => true).headers.sort
    h2 = headers.map(&:name).sort
    (h1 - h2).blank? && (h2 - h1).blank?
  end

  def create_lines(data)
    case filetype
    when 'csv'
      csv = CSV.parse(data, :headers => true)
      csv.each_with_index do |row, index|
        values = row.to_hash
        lines.create values: values, number: index + 1, uid: values[uid]
      end
    when 'xml'
      doc = Nokogiri::XML(data)
      posts = doc.css(post_mapping)

      posts.each_with_index do |post, index|
        values = {}
        headers.each do |node|
          values[node.name] = post.at_css(node.name).content
        end
        lines.create values: values, number: index + 1, uid: values[uid]
      end
    end
  end

  def update_lines(data)
    case filetype
    when 'csv'
      csv = CSV.parse(data, :headers => true)
      csv.each_with_index do |row, index|
        values = row.to_hash
        line = lines.find_by(uid: values[uid])
        if line
          line.update_attributes values: values, number: index + 1, processed: false, error: false, error_messages: nil
        else
          lines.create values: values, number: index + 1, uid: values[uid]
        end
      end
    when 'xml'
      doc = Nokogiri::XML(data)
      posts = doc.css(post_mapping)

      posts.each_with_index do |post, index|
        values = {}
        headers.each do |node|
          values[node.name] = post.at_css(node.name).content
        end
        line = lines.find_by(uid: values[uid])
        if line
          line.update_attributes values: values, number: index + 1, processed: false, error: false, error_messages: nil
        else
          lines.create values: values, number: index + 1, uid: values[uid]
        end
      end
    end
  end

  def mapped_headers
    headers.select { |h| h.registration_question_id.present? || h.column_name.present? }
  end

  def filetype
    filename.split('.').last
  end
end