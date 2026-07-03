# frozen_string_literal: true

# Maps the classic H004 order codes (CCT, CDD, C53, ...) to their EBICS 3.0
# (H005) BTF Service descriptors, so the existing convenience API keeps working
# when a client is configured with `version: :h005`.
#
# This is a *starter set* for German (DE) banks. The message versions below are
# the commonly used ISO 20022 versions but ARE bank-specific — verify them
# against your bank's BTF mapping / "Auftragsarten" annex and override via the
# raw Epics::Client#BTU / #BTD API (passing an Epics::BTF) when they differ.
#
# Unmapped codes raise, pointing the caller at the raw BTU/BTD API.
module Epics::BtfMapping
  # code => [direction, btf-attributes]
  UPLOADS = {
    'CCT' => { service_name: 'SCT', scope: 'DE', msg_name: 'pain.001', msg_version: '03' },
    'CCS' => { service_name: 'SCT', scope: 'DE', msg_name: 'pain.001', msg_version: '03' },
    'CDD' => { service_name: 'SDD', service_option: 'COR', scope: 'DE', msg_name: 'pain.008', msg_version: '02' },
    'CDB' => { service_name: 'SDD', service_option: 'B2B', scope: 'DE', msg_name: 'pain.008', msg_version: '02' },
  }.freeze

  DOWNLOADS = {
    'STA' => { service_name: 'EOP', scope: 'DE', msg_name: 'mt940' },
    'C53' => { service_name: 'EOP', scope: 'DE', container: 'ZIP', msg_name: 'camt.053', msg_version: '08' },
    'C52' => { service_name: 'STM', scope: 'DE', container: 'ZIP', msg_name: 'camt.052', msg_version: '08' },
    'C54' => { service_name: 'REP', scope: 'DE', container: 'ZIP', msg_name: 'camt.054', msg_version: '08' },
    'VMK' => { service_name: 'STM', scope: 'DE', msg_name: 'mt942' },
    'PSR' => { service_name: 'PSR', scope: 'DE', msg_name: 'pain.002', msg_version: '03' },
  }.freeze

  module_function

  def upload(code)
    lookup(UPLOADS, code)
  end

  def download(code)
    lookup(DOWNLOADS, code)
  end

  def lookup(table, code)
    attrs = table[code.to_s]
    unless attrs
      raise ArgumentError,
        "No H005 BTF mapping for order code #{code.inspect}. Use the raw " \
        "Epics::Client#BTU / #BTD API with an Epics::BTF instead."
    end
    Epics::BTF.new(**attrs)
  end
end
