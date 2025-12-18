// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import { hooks as colocatedHooks } from "phoenix-colocated/owl";
import topbar from "../vendor/topbar";
// Import ag-grid-community
import {
  createGrid,
  ModuleRegistry as ModuleRegistryGraph,
  AllCommunityModule as AllCommunityModuleGraph,
} from "ag-grid-community";
import "ag-grid-community/styles/ag-grid.css";
import "ag-grid-community/styles/ag-theme-alpine.css";
import {
  AgCharts,
  AllCommunityModule as AllCommunityModuleChart,
  ModuleRegistry as ModuleRegistryChart,
} from "ag-charts-community";

// Register all community modules
ModuleRegistryGraph.registerModules([AllCommunityModuleGraph]);
ModuleRegistryChart.registerModules([AllCommunityModuleChart]);

let CustomHooks = {};

CustomHooks.AgChart = {
  mounted() {
    const chartConfig = {
      container: this.el,
      series: [
        {
          type: "line",
          xKey: "month",
          yKey: "count",
        },
      ],
    };

    this.handleEvent("load_chart", ({ data }) => {
      if (this.chart) {
        this.chart.destroy();
      }
      this.chart = AgCharts.create({
        ...chartConfig,
        data: data,
      });
    });

    this.handleEvent("update_chart", ({ data }) => {
      if (this.chart) {
        // Destroy and recreate for reliable updates
        this.chart.destroy();
        this.chart = AgCharts.create({
          ...chartConfig,
          data: data,
        });
      } else {
        // If chart doesn't exist, create it
        this.chart = AgCharts.create({
          ...chartConfig,
          data: data,
        });
      }
    });
  },
  destroyed() {
    if (this.chart) {
      this.chart.destroy();
    }
  },
};

CustomHooks.AgGrid = {
  mounted() {
    const hook = this;
    let currentFilters = null;
    let gridApi = null;

    const loadingOverlay = document.createElement("div");
    loadingOverlay.className =
      "absolute inset-0 bg-base-100/90 backdrop-blur-sm flex items-center justify-center z-50";
    loadingOverlay.style.display = "none";
    loadingOverlay.innerHTML = `
      <div class="flex flex-col items-center gap-3">
        <span class="loading loading-spinner loading-lg text-primary"></span>
        <span class="text-sm font-medium text-base-content/70">Updating data...</span>
      </div>
    `;

    this.el.style.position = "relative";
    this.el.style.minHeight = "500px";
    this.el.appendChild(loadingOverlay);

    const createDatasource = () => {
      return {
        getRows: (params) => {
          console.log(params);
          hook.pushEvent(
            "get_rows",
            {
              start_row: params.startRow,
              end_row: params.endRow,
              sort_model: params.sortModel,
              filters: currentFilters || {},
            },
            (reply) => {
              if (reply && Array.isArray(reply.row_data)) {
                params.successCallback(reply.row_data, reply.row_count);

                setTimeout(() => {
                  loadingOverlay.style.display = "none";
                }, 100);
              } else {
                console.error("Invalid reply:", reply);
                params.failCallback();
                loadingOverlay.style.display = "none";
              }
            }
          );
        },
      };
    };

    const ColumnTypes = {
      dateFormatter: {
        valueFormatter: (params) => {
          if (!params.value) return "";

          const date = new Date(params.value);

          if (isNaN(date)) return "";

          return new Intl.DateTimeFormat("en-GB", {
            dateStyle: "short",
            timeStyle: "short",
          }).format(date);
        },
      },
      maybeEmptyFormatter: {
        valueFormatter: (params) => {
          if (!params.value) return "N/A";

          return params.value;
        },
      },
    };

    const baseGridOptions = {
      rowModelType: "infinite",
      pagination: true,
      paginationPageSize: 50,
      cacheBlockSize: 100,
      columnTypes: ColumnTypes,
      onRowClicked: (event) => {
        if (event.data?.uuid) {
          hook.pushEvent("row-selected", { uuid: event.data.uuid });
        }
      },
    };

    this.handleEvent(
      "load_grid",
      ({ gridDefs: columnDefs, defaultColDef, filters }) => {
        if (gridApi) {
          gridApi.destroy();
        }

        currentFilters = filters;

        gridApi = createGrid(this.el, {
          ...baseGridOptions,
          columnDefs,
          defaultColDef,
          datasource: createDatasource(),
        });

        this.gridApi = gridApi;
      }
    );

    this.handleEvent("update_grid", ({ filters }) => {
      if (!gridApi) return;

      currentFilters = filters;

      loadingOverlay.style.display = "flex";
      void loadingOverlay.offsetHeight;

      requestAnimationFrame(() => {
        gridApi.purgeInfiniteCache();
      });
    });
  },

  destroyed() {
    if (this.gridApi) {
      this.gridApi.destroy();
    }
  },
};

const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: { ...colocatedHooks, ...CustomHooks },
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener(
    "phx:live_reload:attached",
    ({ detail: reloader }) => {
      // Enable server log streaming to client.
      // Disable with reloader.disableServerLogs()
      reloader.enableServerLogs();

      // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
      //
      //   * click with "c" key pressed to open at caller location
      //   * click with "d" key pressed to open at function component definition location
      let keyDown;
      window.addEventListener("keydown", (e) => (keyDown = e.key));
      window.addEventListener("keyup", (_e) => (keyDown = null));
      window.addEventListener(
        "click",
        (e) => {
          if (keyDown === "c") {
            e.preventDefault();
            e.stopImmediatePropagation();
            reloader.openEditorAtCaller(e.target);
          } else if (keyDown === "d") {
            e.preventDefault();
            e.stopImmediatePropagation();
            reloader.openEditorAtDef(e.target);
          }
        },
        true
      );

      window.liveReloader = reloader;
    }
  );
}
