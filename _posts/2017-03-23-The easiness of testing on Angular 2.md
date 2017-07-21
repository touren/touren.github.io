---
layout: post
title: The easiness of testing on Angular 2
tags: 
    - angular
    - unit-test
---

Writing unit tests on Angular 2 is the easiest tests I have written amount many platforms like .Net, Android, NodeJs. I think it is because its good DNA. Angular 2 has build-in dependency injection and build-in mock utilities and tooling to help you write test.

# Tooling

By default, when you use `ng new {project_name}` to create a new project, the template includes the environment of its test frameworks.

Angular 2 uses two test frameworks:
1. [jasmine](https://jasmine.github.io/) : the test framework
2. [karma](https://karma-runner.github.io/) : the test runner which re-run test after file changes.

Use `npm test` or `ng test` to start karma. Then it will launch a browser and run the tests. and re-run tests every time you make a changes. (Karma's idea is write and run test immediately, which is a good idea but needs time to be adopted).

Furthermore, when you use `ng g c {component_name}` or `ng generate component {component_name}` or `ng g s {service_name}` or `ng generate service {service_name}` to create components or services, the cli also generates {name}.spec.ts files for you. So you don't need to create test files from scratch.


There are four examples to show you how easy to write a test on Angular 2:

# Example 1: Inject Stub Service.
In this example, you can see how to use replace AuthService by AuthServiceStub.
```javascript
// home.component.ts
@Component({
  selector: 'app-home',
  templateUrl: './home.component.html'
})
export class HomeComponent implements OnInit {
  private isLoggedIn: boolean;

  //the injection will inject AuthService for HomeComponent 
  constructor(private authService: AuthService) {
  }

  ngOnInit() {
    this.authService
      .isLoggedIn()
      .then((result) => {
        this.isLoggedIn = result;
      });
  }
}

// home.component.spec.ts
class AuthServiceStub {
  // add a AuthServiceStub which always return true;  
  isLoggedIn(): Promise<boolean> {
    return Promise.resolve(true);
  }
}

describe('HomeComponent', () => {
  let component: HomeComponent;
  let fixture: ComponentFixture<HomeComponent>;

  beforeEach(async(() => {
    // definition the dependency injection for module
    TestBed.configureTestingModule({
      declarations: [HomeComponent],
      // the injection will use AuthServiceStub for AuthService when creates HomeComponent
      providers: [{provide: AuthService, useValue: new AuthServiceStub()}]
    })
      .compileComponents();
  }));

  it('should do something if isLoggedIn', () => {
    fixture = TestBed.createComponent(HomeComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();

    expect(component).toBeTruthy();
  });
});

```

# Example 2: Override Component Properties.
In this example, you can see how to override the template of HomeComponent. Because HomeComponent has many sub-components and sub-components use many other services, so if we use original template we need to mock many services which increases the difficulty of making a test. (in order languages, override the view to make test the controller and the view easier).


```javascript
const template = `
<div id="root" [ngSwitch]="isLoggedIn">
  <h1 *ngSwitchCase="true">Template 1</h1>
  <h1 *ngSwitchCase="false">Template 2</h1>
</div>
`;

describe('HomeComponent', () => {
  let component: HomeComponent;
  let fixture: ComponentFixture<HomeComponent>;

  beforeEach(async(() => {
    // override the template of the HomeComponent
    TestBed.configureTestingModule({
      declarations: [HomeComponent]
    })
      .overrideComponent(HomeComponent, {set: {template: template}})
      .compileComponents();
  }));

  it('should use template 1 if isLoggedIn', () => {
    fixture = TestBed.createComponent(HomeComponent);
    component = fixture.componentInstance;
    component["isLoggedIn"] = true;
    fixture.detectChanges();

    expect(fixture.debugElement.query(By.css("h1")).nativeElement.textContent).toBe("template 1");
  });

  it('should use template 2 if not isLoggedIn', async(() => {
    fixture = TestBed.createComponent(HomeComponent);
    component = fixture.componentInstance;
    component["isLoggedIn"] = false;
    fixture.detectChanges();

    expect(fixture.debugElement.query(By.css("h1")).nativeElement.textContent).toBe("template 2");
  }));
});

```
# Example 3: Mock Router.
In this example, you can see how to use build-in RouterTestingModule to test router.

```javascript
const routes: Routes = [
  {
    path: '',
    data: {name: "home"},
    component: AppMockComponent,
  },
  {
    path: 'login',
    component: MockComponent
  },
  {
    path: 'signup',
    component: MockComponent
  },
  {
    path: 'profile',
    component: MockComponent
  },
  {path: '**', redirectTo: '/', pathMatch: 'full'},
];

describe('AppRouting', () => {
  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [AppMockComponent, MockComponent],
      imports: [
        // use RouterTestingModule for testing router
        RouterTestingModule.withRoutes(routes)
      ],
      providers: []
    })
      .compileComponents();
  }));

  it('common routing test', async(() => {
    const fixture = TestBed.createComponent(AppMockComponent);
    const router: Router = TestBed.get(Router);
    return router
      .navigate(["login"])
      .then(() => {
        expect(router.url).toBe("/login");
      })
      .then(x => router.navigate(["signup"]))
      .then(() => {
        expect(router.url).toBe("/signup");
      })
      .then(x => router.navigate(["profile"]))
      .then(() => {
        expect(router.url).toBe("/profile");
      })
      .then(x => router.navigate(["/"]))
      .then(() => {
        expect(router.url).toBe("/");
      })
  }));
});
```

# Example 4: Mock Http Response.
In this example, you can see how to use build-in MockBackend to Mock Http Response. I love this feature because it makes api testing easier.

```javascript
describe('ApiService', () => {
  beforeEach(() => {
    this.injector = ReflectiveInjector.resolveAndCreate([
      {provide: ConnectionBackend, useClass: MockBackend},
      {provide: RequestOptions, useClass: BaseRequestOptions},
      Http,
      ApiService
    ]);

    this.apiService = this.injector.get(ApiService);
    this.backend = this.injector.get(ConnectionBackend) as MockBackend;
  });

  it('should get a model', fakeAsync(() => {
    this.backend.connections.subscribe((connection: MockConnection) => {
      connection.mockRespond(new Response(new ResponseOptions({
        body: JSON.stringify({data: {attributes: {"prop1": "test"}}}),
      })));
    });

    this.apiService.getData().then((model) => {
      expect(model.prop1).toBe("test");
    });
  }));
});
```

You can visit its [guide](https://angular.io/docs/ts/latest/guide/testing.html) to find more useful features of testing.


Although many other frameworks can do the same things, but Angular 2's test framework is build-in, so it provides many features and easy to write tests. And because the test framework is build-in, you don't need to research other third-party frameworks and hesitate which one should be used and spent time to try them to your projects. Plus, new crews who know Angular 2 might know how to use the same test framework which is a default test framework for developers to learn.