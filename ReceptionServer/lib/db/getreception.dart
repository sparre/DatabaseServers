part of receptionserver.database;

Future<Map> getReception(int id) {
  String sql = '''
      SELECT id, full_name, attributes, enabled
      FROM receptions
      WHERE id = @id 
    ''';

  Map parameters = {'id' : id};
  
  return database.query(_pool, sql, parameters).then((rows) {
    Map data = {};
    if(rows.length == 1) {
      var row = rows.first;
      data =
        {'reception_id' : row.id,
         'full_name'    : row.full_name,
         'enabled'      : row.enabled};
      
      if (row.attributes != null) {
        Map attributes = JSON.decode(row.attributes);
        if(attributes != null) {
          attributes.forEach((key, value) => data.putIfAbsent(key, () => value));
        }
      }
    }

    return data;
  });
}
