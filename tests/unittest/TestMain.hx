import gml.Project;
import ui.preferences.PrefData;
import ui.Preferences;
import file.kind.KGml;
import electron.Electron;
import massive.munit.client.PrintClient;
import massive.munit.client.RichPrintClient;
import massive.munit.client.HTTPClient;
import massive.munit.client.JUnitReportClient;
import massive.munit.client.SummaryReportClient;

/**
 * Auto generated Test Application.
 * Refer to munit command line tool for more information (haxelib run munit)
 */
class TestMain
{
	static function main() new TestMain();

	public function new() {
		// init things that you can't do without:
		Electron.init();
		Preferences.current = PrefData.defValue();
		gml.GmlVersion.init();
		KGml.initSyntaxExtensions();
		Project.open("");
		//
		var suites = new Array<Class<massive.munit.TestSuite>>();
		suites.push(TestSuite);

		#if MCOVER
			var client = new mcover.coverage.munit.client.MCoverPrintClient();
			var httpClient = new HTTPClient(new mcover.coverage.munit.client.MCoverSummaryReportClient());
		#else
			var client = new RichPrintClient();
			var httpClient = new HTTPClient(new SummaryReportClient());
		#end

		var runner:TestRunnerCustom = new TestRunnerCustom(client);
		runner.addResultClient(httpClient);
		//runner.addResultClient(new HTTPClient(new JUnitReportClient()));

		runner.completionHandler = completionHandler;

		#if (js && !nodejs)
			var seconds = 2; // edit here to add some startup delay
			function delayStartup()
			{
				if (seconds > 0)
				{
					seconds--;
					js.Browser.document.getElementById("munit").innerHTML =	"Tests will start in " + seconds + "s...";
					haxe.Timer.delay(delayStartup, 1000);
				}
				else
				{
					js.Browser.document.getElementById("munit").innerHTML = "";
					runner.run(cast suites);
				}
			}
			delayStartup();
		#else
			runner.run(suites);
		#end
	}

	/**
	 * updates the background color and closes the current browser
	 * for flash and html targets (useful for continous integration servers)
	 */
	function completionHandler(successful:Bool)
	{
		try
		{
			#if flash
				flash.external.ExternalInterface.call("testResult", successful);
			#elseif js
				js.Lib.eval("testResult(" + successful + ");");
			#elseif (neko || cpp || java || cs || python || php || hl || eval || lua)
				Sys.exit(0);
			#end
		}
		// if run from outside browser can get error which we can ignore
		catch (e:Dynamic) {}
	}
}