class Lemur::StatusSection
  include StatusPage::Section

  def name
    "Lemur flags"
  end

  def render(io : IO)
    html io do
      table do
        Lemur::FLAGS.each do |flag|
          row do
            th flag.name
            td flag.value.to_s
            td flag.description
          end
        end
      end
    end
  end
end
