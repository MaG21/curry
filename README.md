# Currency Scrapper for the Dominican Republic

This is a simple service that provides the current currency exchange rate for
the Dominican Republic. To do so, we parse the web pages of all the major banks
of the Dominican Republic, those pages are updated on a daily basis by every
bank.

The method used by this application to calculate the mean of the data is the
_Harmonic mean_.

This application is freely available as a service thanks to
_Marcos Organizador de Negocios S.R.L_ here http://api.marcos.do/

Something is wrong with this service?
Please contact us (at) manuel at marcos dot do.

or

you may make a pull request as well, if you see something that needs to be fixed
or better implemented.

### Available actions

``GET /requests``
Returns the total number of requests successefully served up to this moment.

sample response:

	1092 requests.

``GET /rnc/:rnc``
Returns information about the RNC specified by `:rnc`. [JSON serialized]

sample response:

	{
	  "rnc": "131098193",
	  "name": "MARCOS ORGANIZADOR DE NEGOCIOS SRL",
	  "comercial_name": "MARCOS ORGANIZADOR DE NEGOCIOS",
	  "category": "",
	  "payment_regimen": "NORMAL",
	  "status": "ACTIVO"
	}

``GET /ncf/:rnc/:ncf``
Returns true or false, depending if the RNC and the NCF specified by :rnc and
``:ncf`` respectively belongs to the entity associated to ``:rnc``

sample response:

	{
	  "valid": true
	}


``GET /rates``
Returns the exchange rate for euros and dollars from all major banks of the
Dominican Republic. [JSON serialized]

	{
	  "bpd": {
	    "euro": {
	      "buying_rate": "48.15",
	      "selling_rate": "51.90"
	    },
	    "dollar": {
	      "buying_rate": "45.05",
	      "selling_rate": "45.56"
	    },
	    "source": "https://www.popularenlinea.com/_api/web/lists/getbytitle('Rates')/items"
	  },
	  "blh": {
	    "euro": {
	      "buying_rate": "48.00",
	      "selling_rate": "51.00"
	    },
	    "dollar": {
	      "buying_rate": "45.20",
	      "selling_rate": "45.56"
	    },
	    "source": "http://www.blh.com.do/Inicio.aspx"
	  },
	  "progress": {
	    "euro": {
	      "buying_rate": "49.40",
	      "selling_rate": "50.90"
	    },
	    "dollar": {
	      "buying_rate": "45.26",
	      "selling_rate": "45.56"
	    },
	    "source": "http://www.progreso.com.do/index.php"
	  },
	  "bareservas": {
	    "euro": {
	      "buying_rate": "47.00",
	      "selling_rate": "53.00"
	    },
	    "dollar": {
	      "buying_rate": "45.15",
	      "selling_rate": "45.56"
	    },
	    "source": "http://www.banreservas.com/Pages/index.aspx"
	  },
	  "euro_mean": {
	    "buying_rate": "48.12",
	    "selling_rate": "51.68"
	  },
	  "dollar_mean": {
	    "buying_rate": "45.16",
	    "selling_rate": "45.56"
	  }
	}



``GET /central_bank_rates``
Returns the exchange rate for the dollar according to the Central Bank of the
Dominican Republic. [JSON serialized]

sample response:

	{
	  "dollar": {
	    "buying_rate": "",
	    "selling_rate": ""
	  }
	}

## License
Copyright(C) 2015 Marcos Organizador de Negocios S.R.L

This software is released under the terms of the MIT License. For more
information refer to file COPYRIGHT included in this distribution.

