// ── CSAT Sistema RAM — Google Apps Script Backend ──
// ATUALIZAÇÃO: suporte a JSONP (resolve erro de CORS)
//
// Após colar este código:
//   1. Salvar (Ctrl+S)
//   2. Implantar → Gerenciar implantações → editar a existente → Nova versão → Implantar
//   (ou criar nova implantação se preferir)

const SHEET_NAME = 'Respostas';

function doGet(e) {
  e = e || {};
  var callback = (e.parameter && e.parameter.callback) || '';
  var result;

  try {
    var sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(SHEET_NAME);
    if (!sheet) {
      result = { error: 'Planilha "Respostas" não encontrada.' };
    } else {
      var action = (e.parameter && e.parameter.action) || 'submit';

      if (action === 'read') {
        var data = sheet.getDataRange().getValues();
        var rows = [];
        for (var i = 1; i < data.length; i++) {
          rows.push({
            ts:         String(data[i][0] || ''),
            nome:       String(data[i][1] || ''),
            estrelas:   Number(data[i][2] || 0),
            comentario: String(data[i][3] || ''),
            atendente:  String(data[i][4] || '')
          });
        }
        rows.reverse();
        result = { rows: rows };
      } else {
        sheet.appendRow([
          new Date().toISOString(),
          e.parameter.nome       || '',
          parseInt(e.parameter.estrelas) || 0,
          e.parameter.comentario || '',
          e.parameter.atendente  || ''
        ]);
        result = { status: 'ok' };
      }
    }
  } catch (err) {
    result = { error: String(err) };
  }

  var json = JSON.stringify(result);
  if (callback) {
    return ContentService
      .createTextOutput(callback + '(' + json + ')')
      .setMimeType(ContentService.MimeType.JAVASCRIPT);
  }
  return ContentService
    .createTextOutput(json)
    .setMimeType(ContentService.MimeType.JSON);
}

function setup() {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var sheet = ss.getSheetByName(SHEET_NAME);
  if (!sheet) sheet = ss.insertSheet(SHEET_NAME);
  sheet.getRange(1, 1, 1, 5).setValues([['Data', 'Nome', 'Estrelas', 'Comentario', 'Atendente']]);
  sheet.setFrozenRows(1);
  Logger.log('Setup concluído!');
}
