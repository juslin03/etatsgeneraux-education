module Volunteering
  class XlsxService

    @@multiloc_service = MultilocService.new

    def generate_xlsx pc, volunteers, view_private_attributes: false
      xlsx_service = ::XlsxService.new
      columns = [
        {header: 'first_name', f: -> (v) { v.user.first_name }},
        {header: 'last_name',  f: -> (v) { v.user.last_name }},
        {header: 'email',      f: -> (v) { v.user.email }},
        {header: 'date',       f: -> (v) { v.created_at }, skip_sanitization: true}
      ]
      if !view_private_attributes
        columns.select! do |c|
          !%w(email).include?(c[:header])
        end
      end
      pa = Axlsx::Package.new
      pc.causes.order(:ordering).each do |cause|
        # Sheet names can only be 31 characters long
        sheetname = @@multiloc_service.t(cause.title_multiloc)[0..30]
        xlsx_service.generate_sheet pa.workbook, sheetname, columns, volunteers.where(cause: cause)
      end
      pa.to_stream
    end
  end
end
