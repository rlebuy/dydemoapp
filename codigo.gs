function doGet(e) {
  var sheet = SpreadsheetApp.getActiveSpreadsheet();
  var action = e.parameter.action;

  if (action == "facturas") {
    return getFacturas(sheet);
  } else if (action == "envios") {
    return getEnvios(sheet);
  } else if (action == "soportes") {
    return getSoportes(sheet);
  } else if (action == "ventas") {
    return getVentas(sheet);
  } else if (action == "usuarios") {
    return getUsuarios(sheet);
  } else if (action == "actividad") {
    return getActividad(sheet, e);
  } else if (action == "registrar_gestion_factura") {
    return registrarGestionFactura(sheet, e.parameter || {});
  } else if (action == "actualizar_estado_soporte") {
    return actualizarEstadoSoporte(sheet, e.parameter || {});
  } else if (action == "agregar_comentario_soporte") {
    return agregarComentarioSoporte(sheet, e.parameter || {});
  } else {
    return jsonResponse({
      success: false,
      error: "Acción no válida. Usa facturas, envios, soportes, ventas, usuarios o actividad."
    });
  }
}

function doPost(e) {
  var sheet = SpreadsheetApp.getActiveSpreadsheet();
  var payload = {};
  try {
    payload = JSON.parse(e.postData && e.postData.contents ? e.postData.contents : "{}");
  } catch (_) {
    payload = {};
  }

  var action = (payload.action || (e.parameter && e.parameter.action) || "").toString().trim();
  if (!payload.codigo_ticket && e.parameter && e.parameter.codigo_ticket) {
    payload.codigo_ticket = e.parameter.codigo_ticket;
  }
  if (!payload.estado && e.parameter && e.parameter.estado) {
    payload.estado = e.parameter.estado;
  }
  if (!payload.comentario && e.parameter && e.parameter.comentario) {
    payload.comentario = e.parameter.comentario;
  }
  if (!payload.codigo_factura && e.parameter && e.parameter.codigo_factura) {
    payload.codigo_factura = e.parameter.codigo_factura;
  }
  if (!payload.tipo && e.parameter && e.parameter.tipo) {
    payload.tipo = e.parameter.tipo;
  }
  if (!payload.usuario && e.parameter && e.parameter.usuario) {
    payload.usuario = e.parameter.usuario;
  }
  if (action == "actualizar_estado_soporte") {
    return actualizarEstadoSoporte(sheet, payload);
  } else if (action == "agregar_comentario_soporte") {
    return agregarComentarioSoporte(sheet, payload);
  } else if (action == "registrar_gestion_factura") {
    return registrarGestionFactura(sheet, payload);
  }

  return jsonResponse({
    success: false,
    error: "Acción POST no válida. Usa actualizar_estado_soporte o agregar_comentario_soporte."
  });
}

function jsonResponse(data) {
  return ContentService.createTextOutput(JSON.stringify(data))
    .setMimeType(ContentService.MimeType.JSON);
}

function getOrCreateSheetByName(spreadsheet, name) {
  var sh = spreadsheet.getSheetByName(name);
  if (sh) return sh;
  return spreadsheet.insertSheet(name);
}

function getHeaderIndexMap(sh) {
  var lastColumn = sh.getLastColumn();
  if (lastColumn < 1) return {};
  var headers = sh.getRange(1, 1, 1, lastColumn).getValues()[0];
  var map = {};
  for (var i = 0; i < headers.length; i++) {
    var h = (headers[i] || "").toString().trim().toLowerCase();
    if (h) map[h] = i;
  }
  return map;
}

function ensureColumn(sh, headerName) {
  var map = getHeaderIndexMap(sh);
  var key = headerName.toLowerCase();
  if (Object.prototype.hasOwnProperty.call(map, key)) {
    return map[key];
  }
  var newCol = sh.getLastColumn() + 1;
  sh.getRange(1, newCol).setValue(headerName);
  return newCol - 1;
}

function asIsoDate(value) {
  if (!value) return "";
  if (Object.prototype.toString.call(value) === "[object Date]") {
    return value.toISOString();
  }
  return value.toString();
}
// 📄 Facturas
function getFacturas(sheet) {
  var sh = sheet.getSheetByName("Factura");
  if (!sh) return jsonResponse([]);
  var data = sh.getDataRange().getValues();
  if (data.length < 2) return jsonResponse([]);
  var headerMap = getHeaderIndexMap(sh);
  function fromHeaderOrIndex(header, fallback) {
    return Object.prototype.hasOwnProperty.call(headerMap, header) ? headerMap[header] : fallback;
  }
  var estadoIndex = fromHeaderOrIndex("estado", 7);
  var actualizacionIndex = fromHeaderOrIndex("ultima_actualizacion", 8);
  var emisionIndex = fromHeaderOrIndex("fecha_emision", 3);
  var vencimientoIndex = fromHeaderOrIndex("fecha_vencimiento", 4);
  var detalleIndex = fromHeaderOrIndex("detalle", 5);
  var impuestoIndex = fromHeaderOrIndex("impuesto", 6);
  var result = [];
  for (var i = 1; i < data.length; i++) {
    result.push({
      codigo: data[i][0],
      monto: data[i][1],
      correo: data[i][2],
      fecha_emision: asIsoDate(data[i][emisionIndex]),
      fecha_vencimiento: asIsoDate(data[i][vencimientoIndex]),
      detalle: detalleIndex >= 0 ? (data[i][detalleIndex] || "") : "",
      impuesto: impuestoIndex >= 0 ? (data[i][impuestoIndex] || "") : "",
      estado: estadoIndex >= 0 ? (data[i][estadoIndex] || "Pendiente") : "Pendiente",
      ultima_actualizacion: actualizacionIndex >= 0 ? asIsoDate(data[i][actualizacionIndex]) : ""
    });
  }
  return jsonResponse(result);
}

// 📦 Envios
function getEnvios(sheet) {
  var data = sheet.getSheetByName("Envio").getDataRange().getValues();
  var result = [];
  for (var i = 1; i < data.length; i++) {
    result.push({
      objeto: data[i][0],
      codigo_envio: data[i][1],
      correo: data[i][2]
    });
  }
  return ContentService.createTextOutput(JSON.stringify(result)).setMimeType(ContentService.MimeType.JSON);
}

// 🛠️ Soportes
function getSoportes(sheet) {
  var sh = sheet.getSheetByName("Soporte");
  var data = sh.getDataRange().getValues();
  var headerMap = getHeaderIndexMap(sh);
  var estadoIndex = Object.prototype.hasOwnProperty.call(headerMap, "estado") ? headerMap["estado"] : -1;
  var actualizacionIndex = Object.prototype.hasOwnProperty.call(headerMap, "ultima_actualizacion")
    ? headerMap["ultima_actualizacion"]
    : -1;
  var result = [];
  for (var i = 1; i < data.length; i++) {
    result.push({
      tipo_soporte: data[i][0],
      codigo_ticket: data[i][1],
      correo: data[i][2],
      estado: estadoIndex >= 0 ? (data[i][estadoIndex] || "Abierto") : "Abierto",
      ultima_actualizacion: actualizacionIndex >= 0 ? asIsoDate(data[i][actualizacionIndex]) : ""
    });
  }
  return ContentService.createTextOutput(JSON.stringify(result)).setMimeType(ContentService.MimeType.JSON);
}

// 💰 Ventas
function getVentas(sheet) {
  var data = sheet.getSheetByName("Ventas").getDataRange().getValues();
  var result = [];
  for (var i = 1; i < data.length; i++) {
    result.push({
      tipo_venta: data[i][0],
      valor: data[i][1],
      correo: data[i][2]
    });
  }
  return jsonResponse(result);
}

// 👤 Usuarios
function getUsuarios(sheet) {
  var data = sheet.getSheetByName("Usuario").getDataRange().getValues();
  var result = [];
  for (var i = 1; i < data.length; i++) {
    result.push({
      user: data[i][0],
      password: data[i][1]
    });
  }
  return jsonResponse(result);
}

function getActividad(sheet, e) {
  var modulo = (e.parameter.modulo || "").toString().trim().toLowerCase();
  var codigo = (e.parameter.codigo || "").toString().trim();
  if ((modulo != "soportes" && modulo != "facturas") || !codigo) {
    return jsonResponse({
      success: false,
      error: "Parámetros inválidos. Usa modulo=soportes|facturas y codigo=<codigo>."
    });
  }

  var sh = sheet.getSheetByName("Actividad");
  if (!sh || sh.getLastRow() < 2) return jsonResponse([]);
  var data = sh.getDataRange().getValues();
  var rows = [];
  for (var i = 1; i < data.length; i++) {
    var rowModulo = (data[i][0] || "").toString().trim().toLowerCase();
    var rowCodigo = (data[i][1] || "").toString().trim();
    if (rowModulo == modulo && rowCodigo == codigo) {
      rows.push({
        modulo: data[i][0],
        codigo: data[i][1],
        tipo: data[i][2],
        detalle: data[i][3],
        usuario: data[i][4],
        fecha: asIsoDate(data[i][5])
      });
    }
  }
  return jsonResponse(rows);
}

function findSoporteRowByCodigo(sh, codigoTicket) {
  var data = sh.getDataRange().getValues();
  for (var i = 1; i < data.length; i++) {
    var codigo = (data[i][1] || "").toString().trim();
    if (codigo == codigoTicket) return i + 1;
  }
  return -1;
}

function appendActividad(sheet, tipo, codigoTicket, detalle, usuario) {
  return appendActividadModulo(sheet, "soportes", tipo, codigoTicket, detalle, usuario);
}

function appendActividadModulo(sheet, modulo, tipo, codigo, detalle, usuario) {
  var activitySheet = getOrCreateSheetByName(sheet, "Actividad");
  if (activitySheet.getLastRow() == 0) {
    activitySheet.appendRow(["modulo", "codigo", "tipo", "detalle", "usuario", "fecha"]);
  }
  activitySheet.appendRow([modulo, codigo, tipo, detalle, usuario || "app", new Date()]);
}

function findFacturaRowByCodigo(sh, codigoFactura) {
  var data = sh.getDataRange().getValues();
  for (var i = 1; i < data.length; i++) {
    var codigo = (data[i][0] || "").toString().trim();
    if (codigo == codigoFactura) return i + 1;
  }
  return -1;
}

function registrarGestionFactura(sheet, payload) {
  var codigoFactura = (payload.codigo_factura || "").toString().trim();
  var tipo = (payload.tipo || "").toString().trim().toLowerCase();
  var comentario = (payload.comentario || "").toString().trim();
  var usuario = (payload.usuario || "app").toString().trim();
  if (!codigoFactura || !tipo || !comentario) {
    return jsonResponse({ success: false, error: "codigo_factura, tipo y comentario son obligatorios." });
  }

  var facturaSheet = sheet.getSheetByName("Factura");
  if (!facturaSheet) {
    return jsonResponse({ success: false, error: "No existe la hoja Factura." });
  }
  var rowNumber = findFacturaRowByCodigo(facturaSheet, codigoFactura);
  if (rowNumber < 0) {
    return jsonResponse({ success: false, error: "No se encontró la factura." });
  }

  var estadoCol = ensureColumn(facturaSheet, "estado") + 1;
  var actualizacionCol = ensureColumn(facturaSheet, "ultima_actualizacion") + 1;
  var nuevoEstado = "En revisión";
  if (tipo == "problema") nuevoEstado = "En revisión";
  if (tipo == "prorroga") nuevoEstado = "En revisión";
  if (tipo == "plan_pago") nuevoEstado = "En revisión";
  facturaSheet.getRange(rowNumber, estadoCol).setValue(nuevoEstado);
  facturaSheet.getRange(rowNumber, actualizacionCol).setValue(new Date());
  appendActividadModulo(
    sheet,
    "facturas",
    tipo,
    codigoFactura,
    comentario,
    usuario
  );
  return jsonResponse({ success: true });
}

function actualizarEstadoSoporte(sheet, payload) {
  var codigoTicket = (payload.codigo_ticket || "").toString().trim();
  var nuevoEstado = (payload.estado || "").toString().trim();
  var usuario = (payload.usuario || "app").toString().trim();
  if (!codigoTicket || !nuevoEstado) {
    return jsonResponse({ success: false, error: "codigo_ticket y estado son obligatorios." });
  }

  var soporteSheet = sheet.getSheetByName("Soporte");
  if (!soporteSheet) {
    return jsonResponse({ success: false, error: "No existe la hoja Soporte." });
  }

  var rowNumber = findSoporteRowByCodigo(soporteSheet, codigoTicket);
  if (rowNumber < 0) {
    return jsonResponse({ success: false, error: "No se encontró el ticket." });
  }

  var estadoCol = ensureColumn(soporteSheet, "estado") + 1;
  var actualizacionCol = ensureColumn(soporteSheet, "ultima_actualizacion") + 1;
  soporteSheet.getRange(rowNumber, estadoCol).setValue(nuevoEstado);
  soporteSheet.getRange(rowNumber, actualizacionCol).setValue(new Date());

  appendActividad(sheet, "estado", codigoTicket, "Estado actualizado a: " + nuevoEstado, usuario);
  return jsonResponse({ success: true });
}

function agregarComentarioSoporte(sheet, payload) {
  var codigoTicket = (payload.codigo_ticket || "").toString().trim();
  var comentario = (payload.comentario || "").toString().trim();
  var usuario = (payload.usuario || "app").toString().trim();
  if (!codigoTicket || !comentario) {
    return jsonResponse({ success: false, error: "codigo_ticket y comentario son obligatorios." });
  }

  var soporteSheet = sheet.getSheetByName("Soporte");
  if (!soporteSheet) {
    return jsonResponse({ success: false, error: "No existe la hoja Soporte." });
  }
  var rowNumber = findSoporteRowByCodigo(soporteSheet, codigoTicket);
  if (rowNumber < 0) {
    return jsonResponse({ success: false, error: "No se encontró el ticket." });
  }

  var actualizacionCol = ensureColumn(soporteSheet, "ultima_actualizacion") + 1;
  soporteSheet.getRange(rowNumber, actualizacionCol).setValue(new Date());
  appendActividad(sheet, "comentario", codigoTicket, comentario, usuario);
  return jsonResponse({ success: true });
}
