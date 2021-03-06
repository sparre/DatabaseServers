part of contactserver.database;

Future<Map> getReceptionContactList(int receptionId) {
  String sql = '''
    SELECT rcpcon.reception_id, 
           rcpcon.contact_id, 
           rcpcon.wants_messages, 
           rcpcon.attributes, 
           rcpcon.enabled as rcpenabled,
           rcpcon.distribution_list,
           con.full_name, 
           con.contact_type, 
           con.enabled as conenabled,
           (SELECT array_to_json(array_agg(row_to_json(row)))
            FROM (SELECT 
            pn.id, pn.value, pn.kind
            FROM contact_phone_numbers cpn
              JOIN phone_numbers pn on cpn.phone_number_id = pn.id
            WHERE cpn.reception_id = rcpcon.reception_id AND cpn.contact_id = rcpcon.contact_id
            ) row) as phone
    FROM contacts con 
      JOIN reception_contacts rcpcon on con.id = rcpcon.contact_id
    WHERE rcpcon.reception_id = @receptionid''';
  
  Map parameters = {'receptionid' : receptionId};

  return database.query(_pool, sql, parameters).then((rows) {
    List contacts = new List();
    for(var row in rows) {
      Map contact =
        {'reception_id'      : row.reception_id,
         'contact_id'        : row.contact_id,
         'wants_messages'    : row.wants_messages,
         'enabled'           : row.rcpenabled && row.conenabled,
         'full_name'         : row.full_name,
         'distribution_list' : row.distribution_list != null ? JSON.decode(row.distribution_list) : [],
         'contact_type'      : row.contact_type,
         'phones'            : row.phone != null ? JSON.decode(row.phone) : []};

      if (row.attributes != null) {
        Map attributes = JSON.decode(row.attributes);
        if(attributes != null) {
          attributes.forEach((key, value) => contact.putIfAbsent(key, () => value));
        }
      }
      contacts.add(contact);
    }

    return {'contacts': contacts};
  });
}
