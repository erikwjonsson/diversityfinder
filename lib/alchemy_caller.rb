class AlchemyCaller
  load "#{Rails.root}/vendor/alchemyapi_ruby/alchemyapi.rb"

  def send_query_to_alchemy(url)
    alchemyapi = AlchemyAPI.new() # ADD ERROR MESSAGE IF NO KEY EXISTS
    # ======== Concept Tagging ========
    @keyword_entity_check = []
    @keyword_concept_check = []
    response = alchemyapi.entities('url', url, { 'sentiment'=>1 })
    if response['status'] == 'OK'
      @entities_list = JSON.pretty_generate(response)
      for entity in response['entities']
        @keyword_entity_check.push(entity['text'])
      end
    else
      puts 'Error in entity extraction call: ' + response['statusInfo']
    end
    # ======== Concept Tagging ========
    response = alchemyapi.concepts('url', url)
    if response['status'] == 'OK'
      @concepts_list = JSON.pretty_generate(response)
      for concept in response['concepts']
        @keyword_concept_check.push(concept['text'])
      end
    else
      puts 'Error in concept tagging call: ' + response['statusInfo']
    end

    return [@concepts_list, @entities_list, @keyword_concept_check, @keyword_entity_check]
  end

end