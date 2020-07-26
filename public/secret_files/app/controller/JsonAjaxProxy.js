/* 
 * Jsonリクエスト専用プロキシ
 */
Ext.define('TeamDomain.controller.JsonAjaxProxy', {
    extend: 'Ext.data.proxy.Ajax',
    alias: 'proxy.jsonajax',
    doRequest: function(operation, callback, scope) {
        var writer  = this.getWriter(),
            request = this.buildRequest(operation, callback, scope);

        if (operation.allowWrite()) {
            request = writer.write(request);
        }

        if (operation.jsonData) {
            request.jsonData = operation.jsonData;
        }

        Ext.apply(request, {
            headers       : this.headers,
            timeout       : this.timeout,
            scope         : this,
            callback      : this.createRequestCallback(request, operation, callback, scope),
            method        : this.getMethod(request),
            disableCaching: false 
        });

        Ext.Ajax.request(request);

        return request;
    }
});



