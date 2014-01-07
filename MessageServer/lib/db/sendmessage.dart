part of db;

Future<Map> getContactsToMessagesList(List<String> contacts, int orgId) {
  return _pool.connect().then((Connection conn) {
    String sql = '''
SELECT orgcon.organization_id, orgcon.contact_id, orgcon.wants_messages, orgcon.attributes, orgcon.enabled as orgenabled, con.full_name, con.contact_type, con.enabled
FROM contacts con join organization_contacts orgcon on con.id = orgcon.contact_id
WHERE orgcon.organization_id = @orgId
    ''';

    Map parameters = {'orgId' : orgId};

    return conn.query(sql, parameters).toList().then((rows) {
      List contacts = new List();
      for(var row in rows) {
        Map contact =
          {'organization_id' : row.organization_id,
           'contact_id'      : row.contact_id,
           'wants_messages'  : row.wants_messages,
           'attributes'      : JSON.decode(row.attributes),
           'enabled'         : row.enabled,
           'orgenabled'      : row.orgenabled,
           'full_name'       : row.full_name,
           'contact_type'    : row.contact_type};
        contacts.add(contact);
      }

      return {'contacts': contacts};
    }).whenComplete(() => conn.close());
  });
}
